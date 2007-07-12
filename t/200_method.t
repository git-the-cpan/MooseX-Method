use MooseX::Method;
use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 16;

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

  sub _default_method_attributes { {} }

  lives_ok { method foo => sub {} };
}

is_deeply (attr (foo => 1),{ foo => 1 });

isa_ok (positional,'MooseX::Meta::Signature::Positional');

isa_ok (named,'MooseX::Meta::Signature::Named');

isa_ok (semi,'MooseX::Meta::Signature::Semi');

{
  package Foo::Method;

  use Moose;

  extends qw/MooseX::Meta::Method::Signature/;
}

{
  package Foo;

  use Moose;

  use MooseX::Method;
  use Test::More;

  method test1 => sub { 42 };

  can_ok ('Foo','test1');

  is (Foo->test1,42);

  method test2 => positional () => sub { 42 };

  can_ok ('Foo','test2');

  is (Foo->test2,42);

  # custom metaclass

  method test_metaclass => attr (metaclass => 'Foo::Method') => sub {};

  isa_ok (Foo->meta->get_method ('test_metaclass'),'Foo::Method');
}

