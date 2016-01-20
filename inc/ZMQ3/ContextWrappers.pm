package inc::ZMQ3::ContextWrappers;

use Moo;
use namespace::clean;

extends 'inc::ZMQ2::ContextWrappers';

sub init_tt {q(
sub init {
    my ($self) = @_;

    try {
        $self->context_ptr( zmq_ctx_new() );
        $self->check_null('zmq_ctx_new', $self->context_ptr);
    }
    catch {
        $self->context_ptr(-1);
        die $_;
    };

    if ( $self->has_threads ) {
        $self->set(ZMQ_IO_THREADS, $self->threads);
    }

    if ( $self->has_max_sockets ) {
        $self->set(ZMQ_MAX_SOCKETS, $self->max_sockets);
    }
}
)}

sub get_tt {q(
sub get {
    my ($self, $option) = @_;

    my $option_val = zmq_ctx_get($self->context_ptr, $option);
    $self->check_error('zmq_ctx_get', $option_val);

    return $option_val;
}
)}

sub set_tt {q(
sub set {
    my ($self, $option, $option_val) = @_;

    $self->check_error(
        'zmq_ctx_set',
        zmq_ctx_set($self->context_ptr, $option, $option_val)
    );
}
)}

sub proxy_tt {q(
sub proxy {
    my ($self, $frontend, $backend, $capture) = @_;

    $self->check_error(
        'zmq_proxy',
        zmq_proxy(
            $frontend->socket_ptr,
            $backend->socket_ptr,
            defined $capture ? $capture->socket_ptr : undef,
        )
    );
}
)}

sub device_tt {q(
sub device {
    my ($self, $type, $frontend, $backend) = @_;

    $self->bad_version(
        $self->verstr,
        "zmq_device not available in zmq >= 3.x",
    );
}
)}

sub destroy_tt {q(
sub destroy {
    my ($self) = @_;

    return if $self->context_ptr == -1;

    # don't try to cleanup context cloned from another thread
    return unless $self->_tid == current_tid();

    # don't try to cleanup context copied from another process (fork)
    return unless $self->_pid == $$;

    $self->check_error(
        'zmq_ctx_destroy',
        zmq_ctx_destroy($self->context_ptr)
    );

    $self->context_ptr(-1);
}
)}

1;
