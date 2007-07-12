use Moose::Util::TypeConstraints;
use MooseX::Meta::Parameter;
use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 16;

# basic

{
  my $parameter = MooseX::Meta::Parameter->new;

  isa_ok ($parameter,'MooseX::Meta::Parameter');
  
  is ($parameter->verify_argument (foo => 42,1),42);

  is ($parameter->verify_argument (foo => 42,0),42);
}

# required

{
  my $parameter = MooseX::Meta::Parameter->new (required => 1);

  throws_ok { $parameter->verify_argument (foo => 42,0) } qr/Parameter foo must be specified/;

  is ($parameter->verify_argument (foo => 42,1),42);
}

# type

{
  my $parameter = MooseX::Meta::Parameter->new (isa => 'Int');

  is ($parameter->verify_argument (foo => 42,1),42);

  throws_ok { $parameter->verify_argument (foo => 'Foo',1) } qr/Parameter foo is wrong type/;
}

# default value

{
  my $parameter = MooseX::Meta::Parameter->new (default => 42);

  is ($parameter->verify_argument (foo => undef,0),42);
}

# default coderef

{
  my $parameter = MooseX::Meta::Parameter->new (default => sub { 42 });

  is ($parameter->verify_argument (foo => undef,0),42);
}

# coerce

subtype 'SmallInt'
  => as 'Int'
  => where { $_ < 10 };

coerce 'SmallInt'
  => from 'Int'
    => via { 5 };

{
  my $parameter = MooseX::Meta::Parameter->new (isa => 'Int',coerce => 1);

  throws_ok { $parameter->verify_argument (foo => 'Foo',1) } qr/does not support this/;
}
    
{
  my $parameter = MooseX::Meta::Parameter->new (isa => 'SmallInt',coerce => 1);

  throws_ok { $parameter->verify_argument (foo => 'Foo',1) } qr/and couldn't coerce/;

  is ($parameter->verify_argument (foo => 42,1),5);
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

  throws_ok { $parameter->verify_argument (foo => 'Foo',1) } qr/does not do/;

  throws_ok { $parameter->verify_argument (foo => Foo1->new,1) } qr/does not do/;

  throws_ok { $parameter->verify_argument (foo => Foo2->new,1) } qr/does not do/;

  lives_ok { $parameter->verify_argument (foo => Foo3->new,1) };
}

