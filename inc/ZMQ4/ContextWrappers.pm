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

sub z85_encode_tt {q(
sub z85_encode {
    my ($self, $data) = @_;
    
    my $dest_buf = malloc(41);
    
    my $checked_data = substr($data, 0, 32);
    
    $self->check_null(
        'zmq_z85_encode',
        zmq_z85_encode( $dest_buf, $checked_data, length($checked_data) )
    );
    
    my $dest = buffer_to_scalar($dest_buf, 41);
    free($dest_buf);
    
    return $dest;
}
)}

sub z85_decode_tt {q(
sub z85_decode {
    my ($self, $string) = @_;
    
    my $dest_buf = malloc(32);
    
    $self->check_null(
        'zmq_z86_decode',
        zmq_z85_decode($dest_buf, $string)
    );
    
    my $dest = buffer_to_scalar($dest_buf, 32);
    free($dest_buf);
    
    return $dest;
}
)}


1;
