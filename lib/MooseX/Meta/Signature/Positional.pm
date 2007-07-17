package MooseX::Meta::Signature::Positional;

use Moose;

use MooseX::Meta::Parameter;
use Scalar::Util qw/blessed/;

extends qw/MooseX::Meta::Signature/;

sub new {
  my ($class,@parameters) = @_;

  my $self = $class->meta->new_object;

  $self->{'@!parameter_map'} = [];

  foreach my $parameter (@parameters) {
    if (ref $parameter eq 'HASH') {
      if (exists $parameter->{metaclass}) {
        $parameter = $parameter->{metaclass}->new ($parameter);
      } else {
        $parameter = MooseX::Meta::Parameter->new ($parameter);
      }
    }

    confess "Parameter must be a MooseX::Meta::Parameter or coercible into one"
      unless blessed $parameter && $parameter->isa ('MooseX::Meta::Parameter');

    push @{$self->{'@!parameter_map'}},$parameter;
  }

  return $self;
}

sub validate {
  my $self = shift;

  my @args;

  my $pos;

  eval {
    for (0 .. $#{$self->{'@!parameter_map'}}) {
      $pos = $_;

      push @args,$self->{'@!parameter_map'}->[$_]->validate (( $_ <= $#_ ? $_[$_] : ()));
    }
  };

  die "Parameter $pos: $@"
    if $@;

  return @args;
}

1;

