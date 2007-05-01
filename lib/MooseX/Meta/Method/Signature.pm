package MooseX::Meta::Method::Signature;

use Moose;

extends qw/Moose::Meta::Method/;

sub wrap_with_signature {
  my ($class,$signature,$coderef) = @_;

  confess "Signature must do MooseX::Meta::Signature"
    unless blessed $signature &&
           $signature->can ('does') &&
           $signature->does ('MooseX::Meta::Signature');

  my $self = $class->wrap ($coderef);

  $self->{'$!signature'} = $signature;

  return $self;
}

sub get_signature {
  my ($self) = @_;

  return $self->{'$!signature'};
}

1;

