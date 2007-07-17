package MooseX::Meta::Signature::Combined;

use Moose;

use MooseX::Meta::Signature::Named;
use MooseX::Meta::Signature::Positional;

has named_signature => (is => 'rw',isa => 'MooseX::Meta::Signature::Named');

has positional_signature => (is => 'rw',isa => 'MooseX::Meta::Signature::Positional');

has positional_signature_size => (is => 'rw',isa => 'Int');

extends qw/MooseX::Meta::Signature/;

sub new {
  my ($class,@parameters) = @_;

  my $self = $class->meta->new_object;

  my @positional_params;

  my %named_params;

  while (my $param = shift @parameters) {
    if (ref $param) {
      $param->{required} = 1;

      push @positional_params,$param;
    } else {
      $named_params{$param} = shift @parameters;
    }
  }

  $self->named_signature (MooseX::Meta::Signature::Named->new (%named_params));

  $self->positional_signature (MooseX::Meta::Signature::Positional->new (@positional_params));

  $self->positional_signature_size (scalar @positional_params);

  return $self;
}

sub validate {
  my ($self,@args) = @_;

  my @positional_args = (scalar @args <= $self->{positional_signature_size} ? @args : @args[0..($self->{positional_signature_size} - 1)]);

  my %named_args = @args[$self->{positional_signature_size}..$#args];

  return
    $self->{positional_signature}->validate (@positional_args),
    $self->{named_signature}->validate (%named_args);
}

1;

