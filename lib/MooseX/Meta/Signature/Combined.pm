package MooseX::Meta::Signature::Combined;

use Moose;

use MooseX::Meta::Signature::Named;
use MooseX::Meta::Signature::Positional;

has named_signature => (is => 'rw',isa => 'MooseX::Meta::Signature::Named');

has positional_signature => (is => 'rw',isa => 'MooseX::Meta::Signature::Positional');

has positional_signature_size => (is => 'rw',isa => 'Int');

extends qw/MooseX::Meta::Signature/;

sub new {
  my ($class,@parameters) = @_;

  my $self = $class->meta->new_object;

  my @positional_params;

  my %named_params;

  while (my $param = shift @parameters) {
    if (ref $param) {
      $param->{required} = 1;

      push @positional_params,$param;
    } else {
      $named_params{$param} = shift @parameters;
    }
  }

  $self->named_signature (MooseX::Meta::Signature::Named->new (%named_params));

  $self->positional_signature (MooseX::Meta::Signature::Positional->new (@positional_params));

  $self->positional_signature_size (scalar @positional_params);

  return $self;
}

sub validate {
  my ($self,@args) = @_;

  my @positional_args = (scalar @args <= $self->{positional_signature_size} ? @args : @args[0..($self->{positional_signature_size} - 1)]);

  my %named_args = @args[$self->{positional_signature_size}..$#args];

  return
    $self->{positional_signature}->validate (@positional_args),
    $self->{named_signature}->validate (%named_args);
}

1;

__END__

=pod

=head1 NAME

MooseX::Meta::Signature::Combined - Combined signature metaclass

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> use.

=head1 SYNOPSIS

  use MooseX::Meta::Signature::Combined;

  my $signature = MooseX::Meta::Signature::Combined->new (
    { isa => 'Int' },
    foo => { required => 1 },
  );

  my @results;
  
  eval {
    @results = $signature->validate (23,bar => 2);
  };

=head1 METHODS

=head2 validate

Validates the arguments against the signature. The first arguments
must be the positional ones. The named arguments must be in the
form of a hash, unlike the named signature this does not support
hashrefs. Returns a list of the validated positional arguments
and a hashref of the validated named arguments or throws an
exception on validation error.

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

