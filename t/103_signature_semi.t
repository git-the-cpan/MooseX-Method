use MooseX::Meta::Signature::Semi;
use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 4;

# basic

{
  my $signature = MooseX::Meta::Signature::Semi->new ({});

  isa_ok ($signature,'MooseX::Meta::Signature::Semi');

  isa_ok ($signature,'MooseX::Meta::Signature');

  is_deeply ([$signature->verify_arguments (42,foo => 1)],[42,{ foo => 1 }]);
}

# specified (only positional)

{
  my $signature = MooseX::Meta::Signature::Semi->new ({},foo => {});

  throws_ok { $signature->verify_arguments } qr/must be specified/;
}

