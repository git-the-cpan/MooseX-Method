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

sub export {
  my ($self) = @_;

  my $export = {};
  
  for (keys %$self) {
    $export->{$_} = $self->{$_} if defined $self->{$_};
  }

  return $export;
}

1;

__END__

=pod

=head1 NAME

MooseX::Meta::Parameter - Parameter metaclass

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 SYNOPSIS

  use MooseX::Meta::Parameter;

  my $parameter = MooseX::Meta::Parameter->new (isa => 'Int');

  my $result;

  eval {
    $result = $parameter->validate ("foo");
  };

  print Dumper($parameter->export);

=head1 METHODS

=over 4

=item B<validate>

Takes an argument, validates it, and returns the argument or possibly
a coerced version of it. Exceptions are thrown on validation failure.

=item B<export>

Exports a data structure representing the parameter.

=back

=head1 BUGS

Most software has bugs. This module probably isn't an exception. 
If you find a bug please either email me, or add the bug to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>debolaz@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Anders Nor Berle.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

