package MooseX::Meta::Parameter;

use Moose;

use Moose::Util::TypeConstraints;

has name      => (isa => 'Str');
has metaclass => (isa => 'Str');
has isa       => (isa => 'Str');
has does      => (isa => 'Str');
has required  => (isa => 'Bool');
has default   => (isa => 'Defined');
has coerce    => (isa => 'Bool');

sub verify_argument {
  my ($self,$value,$provided) = @_;

  my $name = (defined $self->{name} ? $self->{name} : 'unnamed');

  if (! $provided && defined $self->{default}) {
    if (ref $self->{default} eq 'CODE') {
      $value = $self->{default}->();
    } else {
      $value = $self->{default};
    }

    $provided = 1;
  }

  confess "Parameter $name must be specified"
    if (! $provided && $self->{required});

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

  return $value;
}

1;

