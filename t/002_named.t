use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 11;

{
  package Foo;

  use Moose;
  use Moose::Util::TypeConstraints;
  use MooseX::Method;
  use Test::Exception;

  subtype SmallInt => as 'Int' => where { $_[0] < 10 };

  coerce SmallInt => from 'Int' => via { 5 };

  method test1 => named (
    num1 => { isa => 'Int',required => 1 },
    num2 => { isa => 'Int',required => 1 },
    num3 => {},
  ) => sub { $_[1]->{num1} + $_[1]->{num2} };

  method test2 => named (
    num1 => { isa => 'Int',default => 50 },
  ) => sub { $_[1]->{num1} };

  method test3 => named (
    num1 => { isa => 'Int',default => sub { 100 } }
  ) => sub { $_[1]->{num1} };

  method test4 => named (
    num1 => { isa => 'Int',default => 'foo' },
  ) => sub {};

  method test5 => named (
    num1 => { isa => 'SmallInt',coerce => 1 },
  ) => sub { $_[1]->{num1} };

  method test6 => named (
    num1 => { isa => 'Int',coerce => 1 },
  ) => sub {};

  method test7 => named (
    num1 => { isa => 'SmallInt',coerce => 1,default => '50' },
  ) => sub { $_[1]->{num1} };
}

throws_ok { Foo->test1 } qr/must be specified/,'required';

throws_ok { Foo->test1 (num1 => 'foo',num2 => 5) } qr/wrong type/,'typecheck';

is (Foo->test1 (num1 => 2,num2 => 3),5,'hash argument');

is (Foo->test1 ({ num1 => 2,num2 => 3 }),5,'hashref argument');

is (Foo->test2,50,'default');

is (Foo->test3,100,'default sub');

throws_ok { Foo->test4 } qr/wrong type/,'default typecheck';

throws_ok { Foo->test5 (num1 => 'foo') } qr/couldn't coerce/,'coerce fail';

is (Foo->test5 (num1 => 20),5,'coerce');

throws_ok { Foo->test6 (num1 => 'foo') } qr/does not support this/,'coerce typecheck';

is (Foo->test7,5,'default coerce');

