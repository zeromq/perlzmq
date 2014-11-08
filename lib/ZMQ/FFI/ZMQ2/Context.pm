package ZMQ::FFI::ZMQ2::Context;

use Moo;
use namespace::autoclean;

use FFI::Raw;
use Carp;
use Try::Tiny;

use ZMQ::FFI::ZMQ2::Socket;
use ZMQ::FFI::Constants qw(ZMQ_STREAMER);

extends qw(ZMQ::FFI::ContextBase);

has '+threads' => (
    default => 1,
);

has _ffi => (
    is      => 'ro',
    lazy    => 1,
    builder => '_init_ffi',
);

sub BUILD {
    my $self = shift;

    if ($self->has_max_sockets) {
        die "max_sockets option not available for ZMQ2\n".
            $self->_verstr;
    }

    try {
        $self->_ctx( $self->_ffi->{zmq_init}->($self->threads) );
        $self->check_null('zmq_init', $self->_ctx);
    }
    catch {
        $self->_ctx(-1);
        die $_;
    };
}

sub get {
    my $self = shift;

    croak
        "getting ctx options not implemented for ZMQ2\n".
        $self->_verstr;
}

sub set {
    my $self = shift;

    croak
        "setting ctx options not implemented for ZMQ2\n".
        $self->_verstr;
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

# zeromq v2 does not provide zmq_proxy; implemented here in terms of zmq_device
sub proxy {
    my ($self, $front, $back, $capture) = @_;

    croak "zeromq v2 does not support a capture socket" if defined $capture;

    $self->check_error(
        'zmq_device',
        $self->_ffi->{zmq_device}->(ZMQ_STREAMER, $front->_socket, $back->_socket)
    );
}

sub destroy {
    my $self = shift;

    $self->check_error(
        'zmq_term',
        $self->_ffi->{zmq_term}->($self->_ctx)
    );

    $self->_ctx(-1);
}

sub _init_ffi {
    my $self = shift;

    my $ffi    = {};
    my $soname = $self->soname;

    $ffi->{zmq_init} = FFI::Raw->new(
        $soname => 'zmq_init',
        FFI::Raw::ptr, # returns ctx ptr
        FFI::Raw::int  # num threads
    );

    $ffi->{zmq_device} = FFI::Raw->new(
        $soname => 'zmq_device',
        FFI::Raw::int, # error code
        FFI::Raw::int, # type
        FFI::Raw::ptr, # frontend
        FFI::Raw::ptr, # backend
    );

    $ffi->{zmq_term} = FFI::Raw->new(
        $soname => 'zmq_term',
        FFI::Raw::int, # retval
        FFI::Raw::ptr  # ctx pt
    );

    return $ffi;
}

sub _verstr {
    my $self = shift;
    return "your version: ".join('.', $self->version);
}

__PACKAGE__->meta->make_immutable();

