use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 24;

{
  package My::Metaclass;

  use Moose;

  extends qw/MooseX::Meta::Parameter/;
}

{
  package XXX1;

  use Test::More;

  eval 'use MooseX::Method';
  
  like $@,qr/not have a metaobject/;
}

{
  package Foo;

  use Moose;
  use MooseX::Method;
  use Test::Exception;

  throws_ok { method undef() => named () => sub {} } qr/must supply a method name/;

  throws_ok { method bless({},'Foo') => named () => sub {} } qr/must supply a method name/;

  throws_ok { method xxx => bless ({},'XXX3') => named () => sub {} } qr/no idea/;

  throws_ok { method xxx => bless ({},'Foo') => sub {} } qr/no idea/;

  throws_ok { method xxx => named (foo => 0) => sub {} } qr/Parameter must/,'parameter declaration';

  throws_ok { method xxx => sub {} } qr/provide a signature/;

  throws_ok { method xxx => named () } qr/provide a coderef/;
}

{
  package Foo::Attr::DefaultError;

  use Moose;
  use MooseX::Method;
  use Test::Exception;

  sub _default_method_attributes { 0 }

  throws_ok { method xxx => named () => sub {} } qr/not return a hashref/;
}

{
  package Foo::Attr::Method;

  use Moose;

  extends qw/MooseX::Meta::Method::Signature/;
}

{
  package Foo::Attr;

  use Moose;
  use MooseX::Method;
  use Test::More;

  my $custom_method = method test1 => attr (metaclass => 'Foo::Attr::Method') => named () => sub { 42 };

  isa_ok $custom_method,'Foo::Attr::Method';
}

is (Foo::Attr->test1,42);

{
  package Foo::Attr::Default;

  use Moose;
  use MooseX::Method;
  use Test::Exception;

  sub _default_method_attributes { {
    } }

  method test1 => named () => sub { 42 };
}

is (Foo::Attr::Default->test1,42);

throws_ok { MooseX::Meta::Method::Signature->wrap_with_signature (0,sub {}) } qr/Signature is not/;

throws_ok { MooseX::Meta::Method::Signature->wrap_with_signature (bless ({},'XXX3'),sub {}) } qr/Signature is not/;

throws_ok { MooseX::Meta::Method::Signature->wrap_with_signature (bless ({},'Foo'),sub {}) } qr/Signature is not/;

throws_ok { MooseX::Meta::Signature::Named->new (foo => 0) } qr/must be a/;

throws_ok { MooseX::Meta::Signature::Positional->new (0) } qr/must be a/;

throws_ok { MooseX::Meta::Signature::Named->new (foo => bless {},'Foo') } qr/must be a/,'signature new isa';

throws_ok { MooseX::Meta::Signature::Positional->new (bless {},'Foo') } qr/must be a/;

my $named_signature = MooseX::Meta::Signature::Named->new (foo => { metaclass => 'My::Metaclass' });

ok $named_signature->isa ('MooseX::Meta::Signature');

ok $named_signature->get_parameter_map,'signature get_parameter_map';

my $test_method = MooseX::Meta::Method::Signature->wrap_with_signature ($named_signature,sub {});

ok $test_method->get_signature;

my $positional_signature = MooseX::Meta::Signature::Positional->new ({ metaclass => 'My::Metaclass' });

ok $positional_signature->isa ('MooseX::Meta::Signature');

ok $positional_signature->get_parameter_map;

