use Test::More;

use strict;
use warnings;

plan tests => 5;

use_ok ('MooseX::Meta::Parameter');

use_ok ('MooseX::Meta::Signature::Named');

use_ok ('MooseX::Meta::Signature::Positional');

use_ok ('MooseX::Meta::Signature::Combined');

use_ok ('MooseX::Method');

