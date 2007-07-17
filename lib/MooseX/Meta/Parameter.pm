package MooseX::Meta::Parameter;

use Moose;

use Moose::Util::TypeConstraints;

has metaclass => (isa => 'Str');
has isa       => (isa => 'Str');
has does      => (isa => 'Str');
has required  => (isa => 'Bool');
has default   => (isa => 'Defined');
has coerce    => (isa => 'Bool');

sub validate {
  my ($self,$value) = @_;

  my $provided = ($#_ > 0 ? 1 : 0);

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
          die "Wants to coerce but type $self->{isa} does not support this\n"
            unless $type->has_coercion;

          my $return = $type->coerce ($value);

          die "Wrong type (got '$return' which isn't a '$self->{isa}') and couldn't coerce\n"
            unless $type->check ($return);

          $value = $return;
        } else {
          die "Wrong type (got '$value' which isn't a '$self->{isa}')\n";
        }
      }
    }

    if (defined $self->{does}) {
      unless (blessed $value && $value->can ('does') && $value->does ($self->{does})) {
        die "Does not do '$self->{does}'\n";
      }
    }
  } elsif ($self->{required}) {
    die "Must be specified\n";
  }

  return $value;
}

1;

