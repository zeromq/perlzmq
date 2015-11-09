package ZMQ::FFI::ZMQ2::Context;

use FFI::Platypus;
use ZMQ::FFI::Util qw(zmq_soname current_tid);
use ZMQ::FFI::Constants qw(ZMQ_STREAMER);
use ZMQ::FFI::ZMQ2::Socket;
use Try::Tiny;

use Moo;
use namespace::clean;

with qw(
    ZMQ::FFI::ContextRole
    ZMQ::FFI::ErrorHelper
    ZMQ::FFI::Versioner
);

has '+threads' => (
    default => 1,
);

my $FFI_LOADED;

sub BUILD {
    my ($self) = @_;

    unless ($FFI_LOADED) {
        _load_zmq2_ffi($self->soname);
        $FFI_LOADED = 1;
    }

    if ($self->has_max_sockets) {
        $self->bad_version(
            $self->verstr,
            'max_sockets option not available in zmq 2.x',
            'use_die',
        )
    }

    try {
        $self->_ctx( zmq_init($self->threads) );
        $self->check_null('zmq_init', $self->_ctx);
    }
    catch {
        $self->_ctx(-1);
        die $_;
    };
}

sub _load_zmq2_ffi {
    my ($soname) = @_;

    my $ffi = FFI::Platypus->new( lib => $soname );

    $ffi->attach(
        # void *zmq_init(int io_threads)
        'zmq_init' => ['int'] => 'pointer'
    );

    $ffi->attach(
        # int zmq_device(int device, const void *front, const void *back)
        'zmq_device' => ['int', 'pointer', 'pointer'] => 'int'
    );

    $ffi->attach(
        # int zmq_term(void *context)
        'zmq_term' => ['pointer'] => 'int'
    );

    $ffi->attach(
        # const char *zmq_strerror(int errnum)
        'zmq_strerror' => ['int'] => 'string'
    );

    $ffi->attach(
        # int zmq_errno(void)
        'zmq_errno' => [] => 'int'
    );
}

sub get {
    my ($self) = @_;

    $self->bad_version(
        $self->verstr,
        "getting ctx options not available in zmq 2.x"
    );
}

sub set {
    my ($self) = @_;

    $self->bad_version(
        $self->verstr,
        "setting ctx options not available in zmq 2.x"
    );
}

sub socket {
    my ($self, $type) = @_;

    return ZMQ::FFI::ZMQ2::Socket->new(
        ctx          => $self,
        type         => $type,
        soname       => $self->soname,
    );
}

# zeromq v2 does not provide zmq_proxy
# implemented here in terms of zmq_device
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
        zmq_device(ZMQ_STREAMER, $frontend->_socket, $backend->_socket)
    );
}

sub device {
    my ($self, $type, $frontend, $backend) = @_;

    $self->check_error(
        'zmq_device',
        zmq_device($type, $frontend->_socket, $backend->_socket)
    );
}

sub destroy {
    my ($self) = @_;

    return if $self->_ctx == -1;

    # don't try to cleanup context cloned from another thread
    return unless $self->_tid == current_tid();

    # don't try to cleanup context copied from another process (fork)
    return unless $self->_pid == $$;

    $self->check_error(
        'zmq_term',
        zmq_term($self->_ctx)
    );

    $self->_ctx(-1);
}

sub DEMOLISH {
    my ($self) = @_;

    return if $self->_ctx == -1;

    $self->destroy();
}

1;
