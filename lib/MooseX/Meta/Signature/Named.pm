package MooseX::Meta::Signature::Named;

use Moose;

use MooseX::Meta::Parameter;
use Scalar::Util qw/blessed/;

with qw/MooseX::Meta::Signature/;

sub new {
  my ($class,$parameters) = @_;

  my $self = $class->meta->new_object;

  $self->{'%!parameter_map'} = {};

  confess "Parameter declaration must be a hashref"
    unless ref $parameters eq 'HASH';
  
  for (keys %{$parameters}) {
    my $parameter = $parameters->{$_};

    if (ref $parameter eq 'HASH') {
      if (exists $parameter->{metaclass}) {
        $parameter = $parameter->{metaclass}->new ($parameter);
      } else {
        $parameter = MooseX::Meta::Parameter->new ($parameter);
      }
    }

    confess "Parameter must be a MooseX::Meta::Parameter or coercible into one"
      unless blessed $parameter && $parameter->isa ('MooseX::Meta::Parameter');

    $self->{'%!parameter_map'}->{$_} = $parameter;
  }

  return $self;
}

sub verify_arguments {
  my $self = shift;

  my $args;

  if (ref $_[0] eq 'HASH') {
    $args = $_[0];
  } else {
    $args = { @_ };
  }

  $args->{$_} = $self->{'%!parameter_map'}->{$_}->verify_argument ($_,$args->{$_},exists $args->{$_})
    for (keys %{$self->{'%!parameter_map'}});

  return $args;
}

sub get_parameter_map {
  my ($self) = @_;

  return $self->{'%!parameter_map'};
}

1;

