package MooseX::Meta::Method::Signature;

use Moose;

extends qw/Moose::Meta::Method/;

sub wrap_with_signature {
  my ($class,$signature,$coderef) = @_;

  confess "Signature is not a MooseX::Meta::Signature"
    unless blessed $signature && $signature->isa ('MooseX::Meta::Signature');

  my $self = $class->wrap ($coderef);

  $self->{'$!signature'} = $signature;

  return $self;
}

1;

