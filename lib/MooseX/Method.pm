package MooseX::Method;

use Moose;

use Carp qw/croak/;
use Class::MOP;
use Exporter;
use Moose::Meta::Class;
use MooseX::Meta::Method::Signature;
use MooseX::Meta::Signature::Named;
use MooseX::Meta::Signature::Positional;
use MooseX::Meta::Signature::Combined;
use Scalar::Util qw/blessed/;
use Sub::Name qw/subname/;

our $VERSION = '0.36';

our @EXPORT = qw/method attr named positional combined semi/;

sub import {
  my $class = caller;

  Moose::Meta::Class->initialize ($class)
    unless Class::MOP::does_metaclass_exist ($class);

  goto &Exporter::import;
}

sub method {
  my $name = shift;

  confess "You must supply a method name"
    unless $name && ! ref $name;

  my $class = caller;

  my ($signature,$coderef,$method);

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

  my $meta = Class::MOP::get_metaclass_by_name ($class);

  # This is a workaround for Devel::Cover. It has the nice sideffect
  # of making dispatch wrapping redundant though.
  $meta->add_package_symbol ("&__real_${name}" => $coderef);
   
  if (defined $signature) { 
    $method = $method_metaclass->wrap_with_signature ($signature,sub {
        my $self = shift;

        eval {
          @_ = ($self,$signature->validate (@_));
        };

        croak $@
          if $@;

        goto $coderef;
      });
  } else {
    $method = $method_metaclass->wrap ($coderef);
  }
  
  $meta->add_method ($name => $method);

  return $method;
}

sub attr {
  my (%attributes) = @_;

  return \%attributes;
}

sub named { MooseX::Meta::Signature::Named->new (@_) }

sub positional { MooseX::Meta::Signature::Positional->new (@_) }

sub combined { MooseX::Meta::Signature::Combined->new (@_) }

*semi = \&combined;

1;

__END__

=pod

=head1 NAME

MooseX::Method - Method declaration with type checking

=head1 SYNOPSIS

  package Foo;

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

  method greet => combined (
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

  method $name => sub {};

  method $name => named () => sub {};

The exported function method installs a method into the class from
which it is called from. The first parameter it takes is the name of
the method. The rest of the parameters needs not be in any particular
order, though it's probably best for the sake of readability to keep
the subroutine at the end.

There are two different elements you need to be aware of, the
signature and the parameter. A signature is (For the purpose of this
document) a collection of parameters. A parameter is a collection of
requirements that an individual argument needs to satisfy. No matter
what kind of signature you use, these properties are declared the
same way, although specific properties may behave differently
depending on the particular signature type.

As of version 0.31 of this module, signatures are optional in method
declarations. If one is not provided, arguments will be passed
directly to the coderef.

=head2 Signatures

MooseX::Method comes with three different signature types, and you
will once the internal API becomes stable be able to implement your
own signatures easily.

The three different signatures types are shown below:

  named (
    foo => { isa => 'Int',required => 1 },
    bar => { isa => 'Int' },
  )

  # And methods declared are called like...

  $foo->mymethod (foo => 1,bar => 2);

  positional (
    { isa => 'Int',required => 1 },
    { isa => 'Int' },
  )

  $foo->mymethod (1,2);

  combined (
    { isa => 'Int' },
    foo => { isa => 'Int' },
  )

  $foo->mymethod (1,foo => 2);

The named signature type will let you specify names for the individual
parameters. The example above declares two parameters, foo and bar,
of which foo is mandatory. Read more about parameter properties below.

The positional signature type lets you, unsurprisingly, declare
positional unnamed parameters. If a parameter has the 'required'
property set in a positional signature, a parameter is counted as
provided if the argument list is equal or larger to its position. One
thing about this is that it leads to a situation where a parameter
is implicitly required if a later parameter is explicitly required.
Even so, you should always mark all required parameters explicitly.

The combined signature type combines the two signature types above. You
may declare both named and positional parameters. Parameters do not
need to come in any particular order (Although positional parameters
must be ordered right relative to each other like with the positional
signature) so it's possible to declare a combined signature like this:

  combined (
    { isa => 'Int' },
    foo => { isa => 'Int' },
    { isa => 'Int' },
    bar => { isa => 'Int' },
  )

This is however not recommended for the sake of readability. Put
positional arguments first, then named arguments last, which
is the same order combined signature methods receive them in. Be also
aware that all positional parameters are always required in a combined
signature. Named parameters may be both optional or required
however.

B<Note: "combined" used to be known as "semi". You can still use
"semi" to declare combined signatures, but this will probably
stop working sometimes after version 1.0 is released.>

"combined" used to be known as "semi". You can still use
"semi" to declare combined signatures, but this will probably
stop working sometimes after version 1.0 is released.

=head2 Parameters

Currently, a parameter may set any of the following fields:

=over 4

=item B<isa>

If a value is provided, it must satisfy the constraints of the type
specified in this field. This field should accept the same values
as its counterpart in Moose attributes, see the Moose documentation
for more details on what you can use.

=item B<does>

Require that the value provided is able to do a certain role. It's
implied that the value must also be blessed, although setting this
property does not alter the isa property.

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

=back

=head2 Attributes

To set a method attribute, use the following syntax:

  method foo => attr (
    attribute => $value,
  ) => sub {};

You can set the default method attributes for a class by having a
hashref with them returned from the method _default_method_attributes
like this:

  sub _default_method_attributes { attr (attribute => $value) }

  method foo => attr (
    overridden_attribute => $value,
  ) => sub {};

If you discover any other attributes than those listed here while
diving through the code, they're not guaranteed to be there at the
next release.

=over 4

=item B<metaclass>

Sets the metaclass to use for when creating the method.

=back

=head1 EXPORTED FUNCTIONS

=head2 method

The function for declaring methods.

=head2 named

A function for constructing a named signature.

=head2 positional

A function for constructing a positional signature.

=head2 combined

A function for constructing a combined signature.

=head2 semi

An alias for the combined structure. Will be removed post version 1.0.

=head2 attr

A function for declaring method attributes.

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

=over 4

=item Stevan Little for making Moose and luring me into the
world of metafoo.

=back

=head1 SEE ALSO

=over 4

=item L<Moose>

=item The #moose channel on irc.perl.org

=back

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

