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

sub verify_arguments {
  my $self = shift;

  my @args;

  push @args,$self->{'@!parameter_map'}->[$_]->verify_argument ($_ + 1,$_[$_],($_ <= $#_ ? 1 : 0))
    for (0 .. $#{$self->{'@!parameter_map'}});

  return @args;
}

1;

