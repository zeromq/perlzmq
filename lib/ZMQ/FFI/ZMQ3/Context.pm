package ZMQ::FFI::ZMQ3::Context;

use Moo;
use namespace::autoclean;

use FFI::Raw;
use Carp;
use Try::Tiny;

use ZMQ::FFI::ZMQ3::Socket;
use ZMQ::FFI::Constants qw(ZMQ_IO_THREADS ZMQ_MAX_SOCKETS);

extends q(ZMQ::FFI::ContextBase);

has _ffi => (
    is      => 'ro',
    lazy    => 1,
    builder => '_init_ffi',
);

sub BUILD {
    my $self = shift;

    try {
        $self->_ctx( $self->_ffi->{zmq_ctx_new}->() );
        $self->check_null('zmq_ctx_new', $self->_ctx);
    }
    catch {
        $self->_ctx(-1);
        die $_;
    };

    if ( $self->has_threads ) {
        $self->set(ZMQ_IO_THREADS, $self->threads);
    }

    if ( $self->has_max_sockets ) {
        $self->set(ZMQ_MAX_SOCKETS, $self->max_sockets);
    }
}

sub get {
    my ($self, $option) = @_;

    my $option_val = $self->_ffi->{zmq_ctx_get}->($self->_ctx, $option);
    $self->check_error('zmq_ctx_get', $option_val);

    return $option_val;
}

sub set {
    my ($self, $option, $option_val) = @_;

    $self->check_error(
        'zmq_ctx_set',
        $self->_ffi->{zmq_ctx_set}->($self->_ctx, $option, $option_val)
    );
}

sub socket {
    my ($self, $type) = @_;

    return ZMQ::FFI::ZMQ3::Socket->new(
        ctx          => $self,
        type         => $type,
        soname       => $self->soname,
        error_helper => $self->error_helper,
    );
}

sub destroy {
    my $self = shift;

    $self->check_error(
        'zmq_ctx_destroy',
        $self->_ffi->{zmq_ctx_destroy}->($self->_ctx)
    );

    $self->_ctx(-1);
};

sub _init_ffi {
    my $self = shift;

    my $ffi    = {};
    my $soname = $self->soname;

    $ffi->{zmq_ctx_new} = FFI::Raw->new(
        $soname => 'zmq_ctx_new',
        FFI::Raw::ptr, # returns ctx ptr
        # void
    );

    $ffi->{zmq_ctx_set} = FFI::Raw->new(
        $soname => 'zmq_ctx_set',
        FFI::Raw::int, # error code,
        FFI::Raw::ptr, # ctx
        FFI::Raw::int, # opt constant
        FFI::Raw::int  # opt value
    );

    $ffi->{zmq_ctx_get} = FFI::Raw->new(
        $soname => 'zmq_ctx_get',
        FFI::Raw::int, # opt value,
        FFI::Raw::ptr, # ctx
        FFI::Raw::int  # opt constant
    );

    $ffi->{zmq_ctx_destroy} = FFI::Raw->new(
        $soname => 'zmq_ctx_destroy',
        FFI::Raw::int, # retval
        FFI::Raw::ptr  # ctx to destroy
    );

    return $ffi;
}

__PACKAGE__->meta->make_immutable();

