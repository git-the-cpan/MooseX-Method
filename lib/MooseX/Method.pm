package MooseX::Method;

use Moose;

use Carp qw/confess/;
use Class::MOP;
use Exporter;
use Module::Find;
use Moose::Meta::Class;
use MooseX::Meta::Method::Signature;
use MooseX::Meta::Signature::Named;
use MooseX::Meta::Signature::Positional;
use Scalar::Util qw/blessed/;
use Sub::Name qw/subname/;

our $VERSION = '0.29';

our @EXPORT = qw/method attr named positional semi/;

sub import {
  my $class = caller;

  # MooseX::Method could initialize a metaclass automagically, but I prefer
  # to leave that to the user at this time.

  confess "$class does not have a metaobject (Did you remember to use Moose first?)"
    unless Class::MOP::does_metaclass_exist ($class);

  my @signature_metaclasses = usesub MooseX::Meta::Signature;

  foreach my $signature_metaclass (@signature_metaclasses) {
    my $shorthand = my $filename = $signature_metaclass;

    $shorthand =~ s/.*:://;

    Moose::Meta::Class->create ("MooseX::Signature::$shorthand" =>
      methods => {
        import => sub {
          no strict qw/refs/;

          my $pkg = caller;

          my $constructor_name = $_[1] || lc ($shorthand);

          *{$pkg."::$constructor_name"} = sub {
            return $signature_metaclass->new (@_);
          };
        },
      },
    );

    $INC{"MooseX/Signature/$shorthand.pm"} = 1;
  }

  goto &Exporter::import;
}

sub method {
  my $name = shift;

  confess "You must supply a method name"
    unless $name && ! ref $name;

  my $class = caller;

  my ($signature,$coderef);

  my $local_attributes = {};

  for (@_) {
    if (blessed $_ && $_->isa ('MooseX::Meta::Signature')) {
      $signature = $_;
    } elsif (ref $_ eq 'CODE') {
      $coderef = $_;
    } elsif (ref $_ eq 'HASH') {
      $local_attributes = $_;
    } else {
      confess "I have no idea what to do with '$_'";
    }
  }

  confess "You didn't provide a coderef"
    unless defined $coderef;

  confess "You didn't provide a signature"
    unless defined $signature;

  my $attributes;

  # Have a method that allows default attribute settings for methods.
  if ($class->can ('_default_method_attributes')) {
    $attributes = $class->_default_method_attributes ($name);

    confess "_default_method_attributes exists but does not return a hashref"
      unless ref $attributes eq 'HASH';
  } else {
    $attributes = {};
  }

  $attributes = { %$attributes,%$local_attributes };

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

sub attr {
  my (%attributes) = @_;

  return \%attributes;
}

sub named { MooseX::Meta::Signature::Named->new (@_) }

sub positional { MooseX::Meta::Signature::Positional->new (@_) }

sub semi { MooseX::Meta::Signature::Semi->new (@_) }

1;

__END__

=pod

=head1 NAME

MooseX::Method - Method declaration with type checking

=head1 SYNOPSIS

  package Foo;

  use Moose;
  use MooseX::Method;

  method hello => named (
    who => { isa => 'Str',required => 1 },
    age => { isa => 'Int',required => 1 },
  ) => sub {
    my ($self,$args) = @_;

    print "Hello $args->{who}, I am $args->{age} years old!\n";
  };

  method morning => positional (
    { isa => 'Str',required => 1 },
  ) => sub {
    my ($self,$name) = @_;

    print "Good morning $name!\n";
  };

  method greet => semi (
    { isa => 'Str' },
    excited => { isa => 'Bool',default => 0 },
  ) => sub {
    my ($self,$name,$args) = @_;

    if ($args->{excited}) {
      print "GREETINGS $name!\n";
    } else {
      print "Hi $name!\n";
    }
  };

  Foo->hello (who => 'world',age => 42); # This works.

  Foo->morning ('Jens'); # This too.

  Foo->greet ('Jens',excited => 1); # And this as well.

  Foo->hello (who => 'world',age => 'fortytwo'); # This doesn't.

  Foo->morning; # This neither.

  Foo->greet; # Won't work.

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

  method $name => named () => sub {}

The exported function method installs a method into the class from
which it is called from. The first parameter it takes is the name of
the method. The rest of the parameters needs not be in any particular
order, though it's probably best for the sake of readability to keep
the subroutine at the end.

=head2 Parameters

The parameter specification should look something to this effect:

  named (
    foo => { isa => 'Int',required => 1 },
    bar => { isa => 'Int' },
  )

Or for positional arguments...

  positional (
    { isa => 'Int',required => 1 },
    { isa => 'Int' },
  )

The first example will make MooseX::Method create a method which takes
two parameters, 'foo' and 'bar', of which only 'foo' is mandatory. The
second example will create two positional parameters with the same
properties.

There's also a third type of signature available, which lets you
get the best from both worlds.

  semi (
    { isa => 'Int' },
    foo => { isa => 'Int' },
  )

Here we mix the two previously mentioned signature types, which lets
you call a method with a syntax like:

  Foo->add_item ($item,protected => 1);

A gotcha to be aware of is that all positional parameters becomes
required when using this signature type. Named parameters can still
be mandatory or optional like usual. Also, all positional
arguments must be put first in the argument list like in the example
used. Named parameters are put afterwards.

Currently, a parameter may set any of the following fields:

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

=head2 Attributes

To set a method attribute, use the following syntax:

  method foo => attr (
    attribute => $value,
  ) => named (
    # Regular parameter stuff here
  ) => sub {};

You can set the default method attributes for a class by having a
hashref with them returned from the method _default_method_attributes
like this:

  sub _default_method_attributes { attr (attribute => $value) }

  method foo => attr (
    overridden_attribute => $value,
  ) => named (
    # Regular parameter stuff here
  ) => sub {};

At present time, not many attributes will actually do much.

=over4

=item B<metaclass>

Sets the metaclass to use for when creating the method.

=head1 FUTURE

I'm considering using a param() function to declare individual
parameters, but I feel this might have a bit too high risk of
clashing with existing functions of other modules. Your thoughts on
the subject is welcome.

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

