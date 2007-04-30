package MooseX::Meta::Parameter;

use Moose;

use Moose::Util::TypeConstraints;

has metaclass => (isa => 'Str');
has isa       => (isa => 'Str');
has does      => (isa => 'Str');
has required  => (isa => 'Bool');
has default   => (isa => 'Defined');
has coerce    => (isa => 'Bool');

sub verify_argument {
  my ($self,$name,$value,$provided) = @_;

  if (! $provided && defined $self->{default}) {
    if (ref $self->{default} eq 'CODE') {
      $value = $self->{default}->();
    } else {
      $value = $self->{default};
    }

    $provided = 1;
  }

  if ($provided) {
    if (defined $self->{isa}) {
      my $type = find_type_constraint ($self->{isa});

      unless ($type->check ($value)) {
        if ($self->{coerce}) {
          confess "Parameter $name wants to coerce but type $self->{isa} does not support this"
            unless $type->has_coercion;

          my $return = $type->coerce ($value);

          confess "Parameter $name is wrong type (got '$return' which isn't a '$self->{isa}') and couldn't coerce"
            unless $type->check ($return);

          $value = $return;
        } else {
          confess "Parameter $name is wrong type (got '$value' which isn't a '$self->{isa}')";
        }
      }
    }

    if (defined $self->{does}) {
      unless (blessed $value && $value->can ('does') && $value->does ($self->{does})) {
        confess "Parameter $name does not do '$self->{does}'";
      }
    }
  } elsif ($self->{required}) {
    confess "Parameter $name must be specified";
  }

  return $value;
}

1;

