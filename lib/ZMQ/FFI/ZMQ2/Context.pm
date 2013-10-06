package ZMQ::FFI::ZMQ2::Context;

use Moose;
use namespace::autoclean;

use FFI::Raw;
use Carp;
use Try::Tiny;

use ZMQ::FFI::ZMQ2::Socket;

with qw(ZMQ::FFI::ContextRole);

has '+threads' => (
    default => 1,
);

# ffi functions
my $zmq_init;
my $zmq_term;

sub BUILD {
    my $self = shift;

    $self->_init_zmq2_ffi();

    if ($self->has_max_sockets) {
        croak
            "max_sockets option not available for ZMQ2\n".
            $self->_verstr();
    }

    try {
        $self->_ctx( $zmq_init->($self->_threads) );
        $self->check_null('zmq_init', $self->_ctx);
    }
    catch {
        $self->_ctx(-1);
        croak $_;
    };
}

sub get {
    my $self = shift;

    croak
        "getting ctx options not implemented for ZMQ2\n".
        "your version: ".$self->version;
}

sub set {
    my $self = shift;

    croak
        "setting ctx options not implemented for ZMQ2\n".
        "your version: ".$self->version;
}

sub socket {
    my ($self, $type) = @_;

    return ZMQ::FFI::ZMQ2::Socket->new(
        ctx_ptr => $self->_ctx,
        soname  => $self->soname,
        type    => $type
    );
}

sub destroy {
    my $self = shift;

    $self->check_error(
        'zmq_term',
        $zmq_term->($self->_ctx)
    );

    $self->_ctx(-1);
}

sub _init_zmq2_ffi {
    my $self = shift;

    my $soname = $self->soname;

    $zmq_init = FFI::Raw->new(
        $soname => 'zmq_init',
        FFI::Raw::ptr, # returns ctx ptr
        FFI::Raw::int  # num threads
    );

    $zmq_term = FFI::Raw->new(
        $soname => 'zmq_term',
        FFI::Raw::int, # retval
        FFI::Raw::ptr  # ctx pt
    );
}

__PACKAGE__->meta->make_immutable();

