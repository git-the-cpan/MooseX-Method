use MooseX::Meta::Signature::Named;
use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 9;

# basic

{
  my $signature = MooseX::Meta::Signature::Named->new;

  isa_ok ($signature,'MooseX::Meta::Signature::Named');

  isa_ok ($signature,'MooseX::Meta::Signature');

  is_deeply ($signature->verify_arguments (foo => 1),{ foo => 1 });

  is_deeply ($signature->verify_arguments ({ foo => 1 }),{ foo => 1 });
}

# specified

{
  my $signature = MooseX::Meta::Signature::Named->new (foo => { required => 1 });

  throws_ok { $signature->verify_arguments ({}) } qr/must be specified/;
}

# custom parameter

{
  package Foo::Parameter;

  use Moose;

  extends qw/MooseX::Meta::Parameter/;

  sub verify_argument { 42 };
}

{
  throws_ok { MooseX::Meta::Signature::Named->new (foo => 0) } qr/Parameter must be/;

  throws_ok { MooseX::Meta::Signature::Named->new (foo => bless ({},'Foo')) } qr/Parameter must be/;

  my $signature = MooseX::Meta::Signature::Named->new (foo => Foo::Parameter->new);

  is_deeply ($signature->verify_arguments ({ foo => 1 }),{ foo => 42 });
}

# custom metaclass

{
  my $signature = MooseX::Meta::Signature::Named->new (foo => { metaclass => 'Foo::Parameter' });

  is_deeply ($signature->verify_arguments ({ foo => 1 }),{ foo => 42 });
}

