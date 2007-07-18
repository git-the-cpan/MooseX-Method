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
  
  is ($parameter->validate (42),42);

  ok (!$parameter->validate);
}

# required

{
  my $parameter = MooseX::Meta::Parameter->new (required => 1);

  throws_ok { $parameter->validate } qr/Must be specified/;

#  is ($parameter->validate (42),42);
}

# type

{
  my $parameter = MooseX::Meta::Parameter->new (isa => 'Int');

  is ($parameter->validate (42),42);

  throws_ok { $parameter->validate ('Foo') } qr/Wrong type/;
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

{
  my $parameter = MooseX::Meta::Parameter->new (isa => 'Int',coerce => 1);

  throws_ok { $parameter->validate ('Foo') } qr/does not support this/;
}
    
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

