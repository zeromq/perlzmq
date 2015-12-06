package ZMQ::FFI::ZMQ3::Context;

use FFI::Platypus;
use ZMQ::FFI::Util qw(zmq_soname current_tid);
use ZMQ::FFI::Constants qw(ZMQ_IO_THREADS ZMQ_MAX_SOCKETS);
use ZMQ::FFI::ZMQ3::Socket;
use Try::Tiny;

use Moo;
use namespace::clean;

with qw(
    ZMQ::FFI::ContextRole
    ZMQ::FFI::ErrorHelper
    ZMQ::FFI::Versioner
);

my $FFI_LOADED;

sub BUILD {
    my ($self) = @_;

    unless ($FFI_LOADED) {
        _load_zmq3_ffi($self->soname);
        $FFI_LOADED = 1;
    }

    try {
        # XXX
        # not clear why this is necessary, but the setter doesn't actually
        # take affect if you directly nest the zmq_ctx_new call in the _ctx
        # call... some Class::XSAccessor weirdness/bug? Need to investigate.
        my $c = zmq_ctx_new();
        $self->context_ptr($c);
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

sub _load_zmq3_ffi {
    my ($soname) = @_;

    my $ffi = FFI::Platypus->new( lib => $soname );

    $ffi->attach(
        # void *zmq_ctx_new()
        'zmq_ctx_new' => [] => 'pointer'
    );

    $ffi->attach(
        # int zmq_ctx_get(void *context, int option_name)
        'zmq_ctx_get' => ['pointer', 'int'] => 'int'
    );

    $ffi->attach(
        # int zmq_ctx_set(void *context, int option_name, int option_value)
        'zmq_ctx_set' => ['pointer', 'int', 'int'] => 'int'
    );

    $ffi->attach(
        # void *zmq_socket(void *context, int type)
        'zmq_socket' => ['pointer', 'int'] => 'pointer'
    );

    $ffi->attach(
        # int zmq_proxy(const void *front, const void *back, const void *cap)
        'zmq_proxy' => ['pointer', 'pointer', 'pointer'] => 'int'
    );

    $ffi->attach(
        # int zmq_ctx_destroy (void *context)
        'zmq_ctx_destroy' => ['pointer'] => 'int'
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
    my ($self, $option) = @_;

    my $option_val = zmq_ctx_get($self->context_ptr, $option);
    $self->check_error('zmq_ctx_get', $option_val);

    return $option_val;
}

sub set {
    my ($self, $option, $option_val) = @_;

    $self->check_error(
        'zmq_ctx_set',
        zmq_ctx_set($self->context_ptr, $option, $option_val)
    );
}

sub socket {
    my ($self, $type) = @_;

    my $socket;

    try {
        my $socket_ptr = zmq_socket($self->context_ptr, $type);

        $self->check_null('zmq_socket', $socket_ptr);

        $socket = ZMQ::FFI::ZMQ3::Socket->new(
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

sub device {
    my ($self, $type, $frontend, $backend) = @_;

    $self->bad_version(
        $self->verstr,
        "zmq_device not available in zmq >= 3.x",
    );
}

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

sub DEMOLISH {
    my ($self) = @_;

    return if $self->context_ptr == -1;

    # check defined to guard against
    # undef objects during global destruction
    if (defined $self->sockets) {
        for my $socket (@{$self->sockets}) {
            $socket->close()
                if defined $socket && $socket->socket_ptr != -1;
        }
    }

    $self->destroy();
}

1;
