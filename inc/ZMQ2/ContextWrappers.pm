package inc::ZMQ2::ContextWrappers;

use Moo;
use namespace::clean;

with 'inc::ContextWrapperRole';

sub init_tt {q(
has '+threads' => (
    default => 1,
);

sub init {
    my ($self) = @_;

    if ($self->has_max_sockets) {
        $self->bad_version(
            $self->verstr,
            'max_sockets option not available in zmq 2.x',
            'use_die',
        )
    }

    try {
        $self->context_ptr( zmq_init($self->threads) );
        $self->check_null('zmq_init', $self->context_ptr);
    }
    catch {
        $self->context_ptr(-1);
        die $_;
    };
}
)}

sub get_tt {q(
sub get {
    my ($self) = @_;

    $self->bad_version(
        $self->verstr,
        "getting ctx options not available in zmq 2.x"
    );
}
)}

sub set_tt {q(
sub set {
    my ($self) = @_;

    $self->bad_version(
        $self->verstr,
        "setting ctx options not available in zmq 2.x"
    );
}
)}

sub socket_tt {q(
sub socket {
    my ($self, $type) = @_;

    my $socket;

    try {
        my $socket_ptr = zmq_socket($self->context_ptr, $type);

        $self->check_null('zmq_socket', $socket_ptr);

        $socket = ZMQ::FFI::[% zmqver %]::Socket->new(
            socket_ptr   => $socket_ptr,
            type         => $type,
            soname       => $self->soname,
        );
    }
    catch {
        die $_;
    };

    push @{$self->sockets}, $socket;

    return $socket;
}
)}

# zeromq v2 does not provide zmq_proxy
# implemented here in terms of zmq_device
sub proxy_tt {q(
sub proxy {
    my ($self, $frontend, $backend, $capture) = @_;

    if ($capture){
        $self->bad_version(
            $self->verstr,
            "capture socket not supported in zmq 2.x"
        );
    }

    $self->check_error(
        'zmq_device',
        zmq_device(ZMQ_STREAMER, $frontend->socket_ptr, $backend->socket_ptr)
    );
}
)}

sub device_tt {q(
sub device {
    my ($self, $type, $frontend, $backend) = @_;

    $self->check_error(
        'zmq_device',
        zmq_device($type, $frontend->socket_ptr, $backend->socket_ptr)
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
        'zmq_term',
        zmq_term($self->context_ptr)
    );

    $self->context_ptr(-1);
}
)}

sub curve_keypair_tt {q(
sub curve_keypair {
    my ($self) = @_;
    $self->bad_version(
        $self->verstr,
       "curve_keypair not available in < zmq 4.x"
    );
}
)}

sub has_capability_tt {q(
sub has_capability {
    my ($self) = @_;
    $self->bad_version(
        $self->verstr,
       "has_capability not available in < zmq 4.1"
    );
}
)}

1;
