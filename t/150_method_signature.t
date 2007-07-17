use MooseX::Meta::Method::Signature;
use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 2;

throws_ok { MooseX::Meta::Method::Signature->wrap_with_signature (0,sub {}) } qr/Signature is not a/;

throws_ok { MooseX::Meta::Method::Signature->wrap_with_signature (bless ({},'Foo'),sub {}) } qr/Signature is not a/;

