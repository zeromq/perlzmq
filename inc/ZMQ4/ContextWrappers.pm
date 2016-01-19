package inc::ZMQ4::ContextWrappers;

use Moo;
use namespace::clean;

extends 'inc::ZMQ3::ContextWrappers';

has +lib_imports => (
    is  => 'ro',
    default => q(
use FFI::Platypus::Memory qw(free malloc);
use FFI::Platypus::Buffer qw(buffer_to_scalar);
),
);

sub destroy_tt {q(
sub destroy {
    my ($self) = @_;

    return if $self->context_ptr == -1;

    # don't try to cleanup context cloned from another thread
    return unless $self->_tid == current_tid();

    # don't try to cleanup context copied from another process (fork)
    return unless $self->_pid == $$;

    $self->check_error(
        'zmq_ctx_term',
        zmq_ctx_term($self->context_ptr)
    );

    $self->context_ptr(-1);
}
)}

sub curve_keypair_tt {q(
sub curve_keypair {
    my ($self) = @_;

    my $public_key_buf = malloc(41);
    my $secret_key_buf = malloc(41);

    $self->check_error(
        'zmq_curve_keypair',
        zmq_curve_keypair($public_key_buf, $secret_key_buf)
    );

    my $public_key = buffer_to_scalar($public_key_buf, 41);
    my $secret_key = buffer_to_scalar($secret_key_buf, 41);
    free($public_key_buf);
    free($secret_key_buf);

    return ($public_key, $secret_key);
}
)}

1;
