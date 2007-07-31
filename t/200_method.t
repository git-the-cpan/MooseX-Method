use Moose::Util::TypeConstraints;
use MooseX::Method;
use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 20;

{
  package XXX;

  use MooseX::Method;
  use Test::Exception;

  throws_ok { method } qr/must supply a method name/;

  throws_ok { method sub {} } qr/must supply a method name/;

  throws_ok { method foo => 0 => sub {} } qr/I have no idea/;

  throws_ok { method foo => bless ({},'Foo') } qr/I have no idea/;

  throws_ok { method 'foo' } qr/provide a coderef/;
}

{
  package TestX::DefaultAttr::Fail;

  use MooseX::Method;
  use Test::Exception;

  sub _default_method_attributes { 0 };

  throws_ok { method foo => sub {} } qr/_default_method_attributes exists but does not/;
}

{
  package TestX::DefaultAttr::Success;

  use MooseX::Method;
  use Test::Exception;

  default_attr ();

  lives_ok { method foo => sub {} };
}

is_deeply (attr (foo => 1),{ foo => 1 });

isa_ok (positional,'MooseX::Meta::Signature::Positional');

isa_ok (named,'MooseX::Meta::Signature::Named');

isa_ok (combined,'MooseX::Meta::Signature::Combined');

isa_ok (semi,'MooseX::Meta::Signature::Combined');

{
  package Foo::Method;

  use Moose;

  extends qw/MooseX::Meta::Method::Signature/;
}

{
  package Foo;

  use Moose;

  use Moose::Util::TypeConstraints;
  use MooseX::Method;
  use Test::More;
  use Test::Exception;

  # declaration without signature

  method test1 => sub { 42 };

  can_ok ('Foo','test1');

  is (Foo->test1,42);

  # declaration with signature

  method test2 => positional () => sub { 42 };

  can_ok ('Foo','test2');

  is (Foo->test2,42);

  # custom metaclass

  method test_metaclass => attr (metaclass => 'Foo::Method') => sub {};

  isa_ok (Foo->meta->get_method ('test_metaclass'),'Foo::Method');

  # exceptions

  method test_exception_mxmethod => positional (
    { required => 1 },
  ) => sub {};

  throws_ok { Foo->test_exception_mxmethod } qr/200_method/;

  method test_exception_user_plain => positional (
    { isa => subtype ('Int',where { die 'Foo' }) },
  ) => sub {};

  throws_ok { Foo->test_exception_user_plain (42) } qr/Foo/;

  method test_exception_user_object => positional (
    { isa => subtype ('Int',where { die bless ({},'Foo') }) },
  ) => sub {};

  eval { Foo->test_exception_user_object (42) };

  is (ref $@,'Foo');
}

