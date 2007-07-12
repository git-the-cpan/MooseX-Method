use Data::Dumper;
use MooseX::Meta::Parameter;
use MooseX::Meta::Signature::Positional;
use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 9;

# basic

{
  my $signature = MooseX::Meta::Signature::Positional->new ({});

  isa_ok ($signature,'MooseX::Meta::Signature::Positional');

  isa_ok ($signature,'MooseX::Meta::Signature');

  is_deeply ([$signature->verify_arguments (42)],[42]);
}

# specified

{
  my $signature = MooseX::Meta::Signature::Positional->new ({ required => 1 });

  throws_ok { $signature->verify_arguments } qr/must be specified/;

  is_deeply ([$signature->verify_arguments (42)],[42]);
}

# custom parameter

{
  throws_ok { MooseX::Meta::Signature::Positional->new (42) } qr/Parameter must be a/;

  throws_ok { MooseX::Meta::Signature::Positional->new (bless ({},'Foo')) } qr/Parameter must be a/;

  lives_ok { MooseX::Meta::Signature::Positional->new (MooseX::Meta::Parameter->new) };
}

# custom metaclass

{
  package Foo::Parameter;

  use Moose;
  
  extends qw/MooseX::Meta::Parameter/;

  sub verify_argument { 42 };
}

{
  my $signature = MooseX::Meta::Signature::Positional->new ({ metaclass => 'Foo::Parameter' });

  is_deeply ([$signature->verify_arguments (21)],[42]);
}

