use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 3;

{
  package Foo;

  use Moose;
  use MooseX::Method;

  method test1 => semi (
    { isa => 'Int' },
    { isa => 'Int' },
    verbose => { isa => 'Bool' },
  ) => sub {
    my ($self,$num1,$num2,$args) = @_;
    
    return 42
      if $args->{verbose};

    return $num1 + $num2;
  };
}

is (Foo->test1 (2,3),5);

is (Foo->test1 (2,3,verbose => 1),42);

throws_ok { Foo->test1 (2) } qr/must be specified/;

