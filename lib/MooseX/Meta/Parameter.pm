package MooseX::Meta::Parameter;

use Moose;

use Moose::Util::TypeConstraints;

has metaclass => (isa => 'Str');
has isa       => (isa => 'Str');
has required  => (isa => 'Bool');
has default   => (isa => 'Defined');
has coerce    => (isa => 'Str');

sub verify_argument {
  my ($self,$value,$provided) = @_;

  if (! $provided && defined $self->{default}) {
    if (ref $self->{default} eq 'CODE') {
      $value = $self->{default}->();
    } else {
      $value = $self->{default};
    }

    $provided = 1;
  }

  confess "Required argumment not specified"
    if (! $provided && $self->{required});

  if (defined $self->{isa}) {
    my $type = find_type_constraint ($self->{isa});

    unless ($type->check ($value)) {
      if ($self->{coerce}) {
        confess "Attempting to coerce to a type that cannot coerce"
          unless $type->has_coercion;

        my $return = $type->coerce ($value);

        confess "'$return' is of wrong type (Expected '$self->{isa}') and couldn't be coerced"
          unless $type->check ($return);

        $value = $return;
      } else {
        confess "'$value' is of wrong type (Expected '$self->{isa}')";
      }
    }
  }

  return $value;
}

1;

