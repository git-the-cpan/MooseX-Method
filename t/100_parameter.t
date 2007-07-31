use Moose::Util::TypeConstraints;
use MooseX::Meta::Parameter;
use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 24;

# basic

{
  my $parameter = MooseX::Meta::Parameter->new;

  isa_ok ($parameter,'MooseX::Meta::Parameter');
  
  is ($parameter->validate (42),42);

  ok (!$parameter->validate);
}

# required

{
  my $parameter = MooseX::Meta::Parameter->new (required => 1);

  throws_ok { $parameter->validate } qr/Must be specified/;

#  is ($parameter->validate (42),42);
}

# type constraint

{
  my $parameter = MooseX::Meta::Parameter->new (isa => 'Int');

  is ($parameter->validate (42),42);

  throws_ok { $parameter->validate ('Foo') } qr/Argument isn't/;
}

# tpye constraint - anonymous subtypes

{
  my $parameter = MooseX::Meta::Parameter->new (isa => subtype ('Int',where { $_ < 5 }));

  throws_ok { $parameter->validate (42) } qr/Argument isn't/;
}

throws_ok { MooseX::Meta::Parameter->new (isa => bless ({},'Foo')) } qr/You cannot specify an object as type/;

# type constraint - classes

{
  my $parameter = MooseX::Meta::Parameter->new (isa => 'Foo');

  throws_ok { $parameter->validate (42) } qr/Argument isn't/;

  ok (ref $parameter->validate (bless ({},'Foo')) eq 'Foo');
}

# type constraint - unions

{
  my $parameter = MooseX::Meta::Parameter->new (isa => 'Int | ArrayRef');

  throws_ok { $parameter->validate ('Foo') } qr/Argument isn't/;

  is ($parameter->validate (42),42);

  is_deeply ($parameter->validate ([42]),[42]);
}

# default value

{
  my $parameter = MooseX::Meta::Parameter->new (default => 42);

  is ($parameter->validate,42);
}

# default coderef

{
  my $parameter = MooseX::Meta::Parameter->new (default => sub { 42 });

  is ($parameter->validate,42);
}

# coerce

subtype 'SmallInt'
  => as 'Int'
  => where { $_ < 10 };

coerce 'SmallInt'
  => from 'Int'
    => via { 5 };

throws_ok { MooseX::Meta::Parameter->new (coerce => 1) } qr/does not support this/;

throws_ok { MooseX::Meta::Parameter->new (isa => 'Int',coerce => 1) } qr/does not support this/;
    
{
  my $parameter = MooseX::Meta::Parameter->new (isa => 'SmallInt',coerce => 1);

  throws_ok { $parameter->validate ('Foo') } qr/and couldn't coerce/;

  is ($parameter->validate (42,1),5);
}

# does

{
  package Foo::Role;

  use Moose::Role;
}

{
  package Foo1;

  sub new { bless {},$_[0] }
}

{
  package Foo2;

  use Moose;
}

{
  package Foo3;

  use Moose;

  with qw/Foo::Role/;
}

{
  my $parameter = MooseX::Meta::Parameter->new (does => 'Foo::Role');

  throws_ok { $parameter->validate ('Foo') } qr/Does not do/;

  throws_ok { $parameter->validate (Foo1->new) } qr/Does not do/;

  throws_ok { $parameter->validate (Foo2->new) } qr/Does not do/;

  lives_ok { $parameter->validate (Foo3->new) };
}

# export

{
  my $parameter = MooseX::Meta::Parameter->new (required => 1);

  is_deeply ($parameter->export,{ required => 1 });
}

