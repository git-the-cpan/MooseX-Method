use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 10;

{
  package Foo;

  use Moose;
  use Moose::Util::TypeConstraints;
  use MooseX::Method;
  use Test::Exception;

  subtype SmallInt => as 'Int' => where { $_[0] < 10 };

  coerce SmallInt => from 'Int' => via { 5 };

  method test1 => [ 
    { isa => 'Int',required => 1 },
    { isa => 'Int',required => 1 },
  ] => sub { $_[1] + $_[2] };

  method test2 => [
    { isa => 'Int',default => 50 },
  ] => sub { $_[1] };

  method test3 => [
    { isa => 'Int',default => sub { 100 } },
  ] => sub { $_[1] };

  method test4 => [
    { isa => 'Int',default => 'foo' },
  ] => sub {};

  method test5 => [
    { isa => 'SmallInt',coerce => 1 },
  ] => sub { $_[1] };

  method test6 => [
    { isa => 'Int',coerce => 1 },
  ] => sub {};

  method test7 => [
    { isa => 'SmallInt',coerce => 1,default => '50' },
  ] => sub { $_[1] };
}

throws_ok { Foo->test1 } qr/must be specified/,'required';

throws_ok { Foo->test1 ('foo',5) } qr/wrong type/,'typecheck';

is (Foo->test1 (2,3),5,'positional argument');

is (Foo->test2,50,'default');

is (Foo->test3,100,'default sub');

throws_ok { Foo->test4 } qr/wrong type/,'default typecheck';

throws_ok { Foo->test5 ('foo') } qr/couldn't coerce/,'coerce fail';

is (Foo->test5 (20),5,'coerce');

throws_ok { Foo->test6 ('foo') } qr/does not support this/,'coerce typecheck';

is (Foo->test7,5,'default coerce');

