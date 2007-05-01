use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 5;

{
  package Foo;

  use Moose;
  use MooseX::Method;
  use Test::Exception;

  method test1 => positional (
    { does => 'Foo::Role' },
  ) => sub { $_[1] };
}

{
  package Foo::Role;

  use Moose::Role;
}

{
  package Bar;

  use Moose;

  with qw/Foo::Role/;
}

throws_ok { Foo->test1 (0) } qr/does not do/;

throws_ok { Foo->test1 (Foo->new) } qr/does not do/;

throws_ok { Foo->test1 (bless {},'Baz') } qr/does not do/;

lives_ok { Foo->test1 (Bar->new) };

lives_ok { Foo->test1 };

