use Moose::Util::TypeConstraints;
use MooseX::Meta::Signature::Named;
use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 12;

# basic

{
  my $signature = MooseX::Meta::Signature::Named->new;

  isa_ok ($signature,'MooseX::Meta::Signature::Named');

  isa_ok ($signature,'MooseX::Meta::Signature');

  is_deeply ($signature->validate (foo => 1),{ foo => 1 });

  is_deeply ($signature->validate ({ foo => 1 }),{ foo => 1 });
}

# specified

{
  my $signature = MooseX::Meta::Signature::Named->new (foo => { required => 1 });

  throws_ok { $signature->validate ({}) } qr/Parameter \(foo\): Must be specified/;
}

# custom parameter

{
  package Foo::Parameter;

  use Moose;

  extends qw/MooseX::Meta::Parameter/;

  sub validate { 42 };
}

{
  throws_ok { MooseX::Meta::Signature::Named->new (foo => 0) } qr/Parameter must be/;

  throws_ok { MooseX::Meta::Signature::Named->new (foo => bless ({},'Foo')) } qr/Parameter must be/;

  my $signature = MooseX::Meta::Signature::Named->new (foo => Foo::Parameter->new);

  is_deeply ($signature->validate ({ foo => 1 }),{ foo => 42 });
}

# custom metaclass

{
  my $signature = MooseX::Meta::Signature::Named->new (foo => { metaclass => 'Foo::Parameter' });

  is_deeply ($signature->validate ({ foo => 1 }),{ foo => 42 });
}

# export

{
  my $signature = MooseX::Meta::Signature::Named->new (foo => { required => 1 });

  is_deeply ($signature->export,{ foo => { required => 1 } });
}

# exception handling

{
  my $signature = MooseX::Meta::Signature::Named->new (foo => { isa => subtype ('Int',where { die 'Foo' }) });

  throws_ok { $signature->validate (foo => 43) } qr/Foo/;
}

{
  my $signature = MooseX::Meta::Signature::Named->new (foo => { isa => subtype ('Int',where { die bless ({},'Foo') }) });

  eval { $signature->validate (foo => 43) };

  is (ref $@,'Foo');
}

