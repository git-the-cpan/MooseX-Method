use MooseX::Meta::Signature::Combined;
use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 4;

# basic

{
  my $signature = MooseX::Meta::Signature::Combined->new ({});

  isa_ok ($signature,'MooseX::Meta::Signature::Combined');

  isa_ok ($signature,'MooseX::Meta::Signature');

  is_deeply ([$signature->validate (42,foo => 1)],[42,{ foo => 1 }]);
}

# specified (only positional)

{
  my $signature = MooseX::Meta::Signature::Combined->new ({},foo => {});

  throws_ok { $signature->validate } qr/Parameter 0: Must be specified/;
}

