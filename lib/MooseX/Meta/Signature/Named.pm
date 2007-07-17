package MooseX::Meta::Signature::Named;

use Moose;

use MooseX::Meta::Parameter;
use Scalar::Util qw/blessed/;

extends qw/MooseX::Meta::Signature/;

sub new {
  my ($class,%parameters) = @_;

  my $self = $class->meta->new_object;

  $self->{'%!parameter_map'} = {};

  for (keys %parameters) {
    my $parameter = $parameters{$_};

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

sub validate {
  my $self = shift;

  my $args;

  if (ref $_[0] eq 'HASH') {
    $args = $_[0];
  } else {
    $args = { @_ };
  }

  my $name;

  eval {
    for (keys %{$self->{'%!parameter_map'}}) {
      $name = $_;

      $args->{$_} = $self->{'%!parameter_map'}->{$_}->validate (( exists $args->{$_} ? $args->{$_} : ()));
    }
  };

  die "Parameter '$name': $@"
    if $@;

  return $args;
}

1;

