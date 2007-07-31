package MooseX::Meta::Signature::Positional;

use Moose;

use Carp qw/croak/;
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

    croak "Parameter must be a MooseX::Meta::Parameter or coercible into one"
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

  if ($@) {
    if (blessed $@ && $@->isa ('MooseX::Method::Exception')) {
      $@->error ("Parameter $pos: " . $@->error);

      $@->rethrow;
    } else {
      die $@;
    }
  }

  return @args;
}

sub export {
  my ($self) = @_;

  my $export = [];

  push @$export,$_->export
    for @{$self->{'@!parameter_map'}};

  return $export;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

MooseX::Meta::Signature::Positional - Positional signature metaclass

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 SYNOPSIS

  use MooseX::Meta::Signature::Positional;

  my $signature = MooseX::Meta::Signature::Positional->new (
    { required => 1 }
  );

  my @results;

  eval {
    @results = $signature->validate (42);
  };

=head1 METHODS

=over 4

=item B<validate>

Validate the arguments against the signature. Returns a list of the
validated arguments or throws an exception on validation error.

=item B<export>

Exports a data structure representing the signature.

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

