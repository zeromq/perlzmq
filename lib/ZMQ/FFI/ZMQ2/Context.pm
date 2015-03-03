package ZMQ::FFI::ZMQ2::Context;

use FFI::Platypus;
use ZMQ::FFI::Util qw(zmq_soname);
use ZMQ::FFI::Constants qw(ZMQ_STREAMER);
use ZMQ::FFI::ZMQ2::Socket;
use Try::Tiny;

use Moo;
use namespace::clean;

with qw(
    ZMQ::FFI::ContextRole
    ZMQ::FFI::ErrorHandler
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
        $self->bad_version("max_sockets option not available in zmq 2.x")
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

sub get {
    my ($self) = @_;

    $self->bad_version(
        "getting ctx options not available in zmq 2.x",
        "use_carp"
    );
}

sub set {
    my ($self) = @_;

    $self->bad_version(
        "setting ctx options not available in zmq 2.x",
        "use_carp"
    );
}

sub socket {
    my ($self, $type) = @_;

    return ZMQ::FFI::ZMQ2::Socket->new(
        ctx          => $self,
        type         => $type,
        soname       => $self->soname,
        error_helper => $self->error_helper,
    );
}

# zeromq v2 does not provide zmq_proxy
# implemented here in terms of zmq_device
sub proxy {
    my ($self, $frontend, $backend, $capture) = @_;

    if ($capture){
        $self->bad_version(
            "capture socket not supported in zmq 2.x",
            "use_carp"
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

    $self->check_error(
        'zmq_term',
        zmq_term($self->_ctx)
    );

    $self->_ctx(-1);
}

sub _load_zmq2_ffi {
    my ($soname) = @_;

    my $ffi = FFI::Platypus->new( lib => $soname );

    $ffi->attach(
        'zmq_init' => ['int'] => 'pointer'
    );

    $ffi->attach(
        'zmq_device' => ['int', 'pointer', 'pointer'] => 'int'
    );

    $ffi->attach(
        'zmq_term' => ['pointer'] => 'int'
    );
}

1;
