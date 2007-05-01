package MooseX::Method;

use Moose;

use MooseX::Meta::Method::Signature;
use MooseX::Meta::Signature::Named;
use MooseX::Meta::Signature::Positional;
use Scalar::Util qw/blessed/;
use Carp qw/confess/;
use Exporter qw/import/;
use Sub::Name qw/subname/;

our $VERSION = '0.20';

our @EXPORT = qw/method/;

sub method {
  my ($name,$attributes,$local_attributes,$parameters,$coderef);
 
  my $class = caller;

  # Have a method that allows default attribute settings for methods.
  if ($class->can ('_default_method_attributes')) {
    $attributes = $class->_default_method_attributes ($name);

    confess "_default_method_attributes exists but does not return a hashref"
      unless ref $attributes eq 'HASH';
  } else {
    $attributes = {};
  }

  # We allow 3 or 4 parameter syntax.
  if (scalar @_ == 3) {
    ($name,$parameters,$coderef) = @_;
  } elsif (scalar @_ == 4) {
    ($name,$local_attributes,$parameters,$coderef) = @_;

    confess "Method attribute specification must be a hashref"
      unless ref $local_attributes eq 'HASH';

    $attributes = { %$attributes,%$local_attributes };
  } else {
    confess "Invalid number of parameters in method declaration";
  }

  confess "$class does not have a meta method (Did you remember to load Moose?)"
    unless $class->can ('meta') && blessed $class->meta && $class->meta->isa ('Moose::Meta::Class');

  confess "Expecting a coderef"
    unless ref $coderef eq 'CODE';

  my $signature;

  if (blessed $parameters && $parameters->isa ('MooseX::Meta::Signature')) {
    $signature = $parameters;
  } else {
    if (ref $parameters eq 'HASH') {
      $signature = MooseX::Meta::Signature::Named->new ($parameters);
    } elsif (ref $parameters eq 'ARRAY') {
      $signature = MooseX::Meta::Signature::Positional->new ($parameters);
    } else {
      confess "The signature declaration must be a hashref, arrayref, or a signature object"
    }
  }

  my $method_metaclass = $attributes->{metaclass} || 'MooseX::Meta::Method::Signature';

  subname "$class\::$name", $coderef;

  # This is a workaround for Devel::Cover. It has the nice sideffect
  # of making dispatch wrapping redundant though.
  $class->meta->add_package_symbol ("&${name}__original_ref" => $coderef);
    
  my $method = $method_metaclass->wrap_with_signature ($signature,sub {
      my $self = shift;

      @_ = ($self,$signature->verify_arguments (@_));

      goto $coderef;
    });
  
  $class->meta->add_method ($name => $method);

  return $method;
}

1;

__END__

=pod

=head1 NAME

MooseX::Method - Method declaration with type checking

=head1 SYNOPSIS

  package Foo;

  use Moose;
  use MooseX::Method;

  method hello => {
    who => { isa => 'Str',required => 1 },
    age => { isa => 'Int',required => 1 },
  } => sub {
    my ($self,$args) = @_;

    print "Hello $args->{who}, I am $args->{age} years old!\n";
  };

  method morning => [
    { isa => 'Str',required => 1 },
  ] => sub {
    my ($self,$name) = @_;

    print "Good morning $name!\n";
  };

  Foo->hello (who => 'world',age => 42); # This works.

  Foo->morning ('Jens'); # This too.

  Foo->hello (who => 'world',age => 'fortytwo'); # This doesn't.

  Foo->morning; # This neither.

=head1 DESCRIPTION

=head2 The problem

This module is an attempt to solve a problem I've often encountered
but never really found any good solution for, namely validation of
method parameters. How many times haven't we all found ourselves
writing code like this:

  sub foo {
    my ($self,$args) = @_;

    die "Invalid arg1"
      unless (defined $arg->{bar} && $arg->{bar} =~ m/bar/);
  }

Manual parameter validation is a tedious and repetive process and
maintaining it consistently throughout your code can be downright
hard sometimes. Modules like L<Params::Validate> makes the job a
bit easier but it doesn't do much for elegance and it still
requires more weird code than what should strictly speaking be
neccesary.

=head2 The solution

MooseX::Method to the rescue. It lets you declare what parameters
people should be passing to your method using Moose-style
declaration and Moose types. It doesn't get much Moosier than this.

=head1 DECLARING METHODS

  method $name => {} => sub {}

The exported function method installs a method into the class from
which it is called from. The first parameter it takes is the name of
the method. The second parameter is a signature declaration, for more
information on that, see below. The third parameter is a coderef that
should be run when the method is called assuming that all parameters
satisfies the requirements of the parameter specifications.

=head2 Parameter specifications

The parameter specification should look something to this effect:

  {
    foo => { isa => 'Int',required => 1 },
    bar => { isa => 'Int' }
  }

Or for positional arguments...

  [
    { isa => 'Int',required => 1 },
    { isa => 'Int' },
  ]

The first example will make MooseX::Method create a method which takes
two parameters, 'foo' and 'bar', of which only 'foo' is mandatory. The
second example will create two positional parameters with the same
properties.

Currently, the specification for a parameter may set any of the
following fields:

=over4

=item B<isa>

If a value is provided, it must satisfy the constraints of the type
specified in this field.

=item B<does>

Require that the value provided is able to do a certain role.

=item B<default>

Sets the parameter to a default value if the user does not provide it.

=item B<required>

If this field is set, supplying a value to the method isn't optional
but the value may be supplied by the default field.

=item B<coerce>

If the type supports coercion, attempt to coerce the value provided if
it does not satisfy the requirements of isa. See Moose for examples
of how to coerce.

=item B<metaclass>

This is used as parameter metaclass if specified. If you don't know
what this means, read the documentation for Moose.

=head1 ATTRIBUTES

Warning, support for attributes is at a very early stage and the
syntax for using them is still something that may change. However,
I guarantee that this in any case will not affect the standard syntax.

To set a method attribute, use the following syntax:

  method foo => {
    attribute => $value,
  } => {
    # Regular parameter stuff here
  } => sub {};

You can set the default method attributes for a class by having a
hashref with them returned from the method _default_method_attributes
like this:

  sub _default_method_attributes { { attribute => $value } }

  method foo => {
    override => $value,
  } => {
  } => sub {};

At present time, not many attributes will actually do much.

=over4

=item B<metaclass>

Sets the metaclass to use for when creating the method.

=head1 CAVEATS

Methods are added to the class at runtime, which obviously means
they won't be available to play with at compile-time. Moose won't
mind this but a few other modules probably will. A workaround for
this that sometimes work is to encapsulate the method declarations
in a BEGIN block.

There's also a problem related to how roles are loaded in Moose. Since
both MooseX::Method methods and Moose roles are loaded runtime, any
methods a role requires in some way must be declared before the 'with'
statement. This affects things like 'before' and 'after'.

=head1 ACKNOWLEDGEMENTS

=over4

=item Stevan Little for making Moose and luring me into the
world of metafoo.

=head1 SEE ALSO

=over4

=item L<Moose>

=item The #moose channel on irc.perl.org

=head1 BUGS

Most software has bugs. This module probably isn't an exception. 
If you find a bug please either email me, or add the bug to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>debolaz@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Anders Nor Berle.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

