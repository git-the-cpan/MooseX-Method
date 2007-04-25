package MooseX::Method;

use Moose;

use MooseX::Meta::Method::Signature;
use MooseX::Meta::Signature::Named;
use MooseX::Meta::Signature::Positional;
use Scalar::Util qw/blessed/;
use Carp qw/confess/;
use Exporter qw/import/;

our $VERSION = '0.15';

our @EXPORT = qw/method/;

sub method {
  my ($name,$parameters,$coderef) = @_;

  my $class = caller;

  confess "$class does not have a meta method (Did you remember to load Moose?)"
    unless $class->can ('meta') && blessed $class->meta && $class->meta->isa ('Moose::Meta::Class');

  confess "Expecting a coderef"
    unless ref $coderef eq 'CODE';

  my $signature;

  if (ref $parameters eq 'HASH') {
    $signature = MooseX::Meta::Signature::Named->new ($parameters);
  } elsif (ref $parameters eq 'ARRAY') {
    $signature = MooseX::Meta::Signature::Positional->new ($parameters);
  } else {
    confess "The signature declaration must be a hashref or an arrayref"
  }

  my $method;

  if (my $wrapper_coderef = $class->can ('_dispatch_wrapper')) {
    $method = MooseX::Meta::Method::Signature->wrap_with_signature ($signature,sub {
        my $self = shift;

        @_ = ($self,$name,$coderef,$signature->verify_arguments (@_));

        goto $wrapper_coderef;
      });
  } else {
    $method = MooseX::Meta::Method::Signature->wrap_with_signature ($signature,sub {
        my $self = shift;

        @_ = ($self,$signature->verify_arguments (@_));

        goto $coderef;
      });
  }

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
    who => {
      isa => 'Str',
      required => 1,
    },
    age => {
      isa => 'Int',
      required => 1,
    },
  } => sub {
    my ($self,$args) = @_;

    print "Hello $args->{who}, I am $args->{age} years old!\n";
  };

  Foo->hello (who => 'world',age => 42); # This works.

  Foo->hello (who => 'world',age => 'fortytwo'); # This doesn't.

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
the method. The second parameter is a parameter declaration, for more
information on that, see below. The third parameter is a coderef that
should be run when the method is called assuming that all parameters
satisfies the requirements of the parameter specifications.

=head2 Parameter specifications

The method specification should look something to this effect:

  {
    foo => { isa => 'Int',required => 1 },
    bar => { isa => 'Int' }
  }

This will make MooseX::Method create a method which takes two
parameters, 'foo' and 'bar', of which only 'foo' is mandatory.
Currently, the specification for a parameter may set any of the
following fields:

=over4

=item B<isa>

If a value is provided, it must satisfy the constraints of the type
specified in this field.

=item B<default>

Sets the parameter to a default value if the user does not provide it.

=item B<required>

If this field is set, supplying a value to the method isn't optional
but the value may be supplied by the default field.

=item B<coerce>

If the type supports coercion, attempt to coerce the value provided if
it does not satisfy the requirements of isa. See Moose for examples
of how to coerce.

=head1 CAVEATS

Methods are added to the class at runtime, which obviously means
they won't be available to play with at compile-time. Moose won't
mind this but a few other modules probably will. A workaround for
this is to encapsulate the method declarations in a BEGIN block.

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

