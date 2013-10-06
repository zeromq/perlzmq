package ZMQ::FFI::ZMQ3::Context;

use Moo;
use namespace::autoclean;

use FFI::Raw;
use Carp;

use ZMQ::FFI::ZMQ3::Socket;
use ZMQ::FFI::Constants qw(ZMQ_IO_THREADS ZMQ_MAX_SOCKETS);

use Try::Tiny;

with q(ZMQ::FFI::ContextRole);

has '+threads' => (
    default => 1,
);

# ffi functions
my $zmq_ctx_new;
my $zmq_ctx_set;
my $zmq_ctx_get;
my $zmq_ctx_destroy;

sub BUILD {
    my $self = shift;

    $self->_init_zmq3_ffi();

    try {
        $self->_ctx( $zmq_ctx_new->() );
        $self->check_null('zmq_ctx_new', $self->_ctx);
    }
    catch {
        $self->_ctx(-1);
        croak $_;
    };

    if ( $self->has_threads ) {
        $self->set(ZMQ_IO_THREADS, $self->_threads);
    }

    if ( $self->has_max_sockets ) {
        $self->set(ZMQ_MAX_SOCKETS, $self->_max_sockets);
    }
}

sub get {
    my ($self, $option) = @_;

    my $option_val = $zmq_ctx_get->($self->_ctx, $option);
    $self->check_error('zmq_ctx_get', $option_val);

    return $option_val;
}

sub set {
    my ($self, $option, $option_val) = @_;

    $self->check_error(
        'zmq_ctx_set',
        $zmq_ctx_set->($self->_ctx, $option, $option_val)
    );
}

sub socket {
    my ($self, $type) = @_;

    return ZMQ::FFI::ZMQ3::Socket->new(
        ctx_ptr => $self->_ctx,
        soname  => $self->soname,
        type    => $type
    );
}

sub destroy {
    my $self = shift;

    $self->check_error(
        'zmq_ctx_destroy',
        $zmq_ctx_destroy->($self->_ctx)
    );

    $self->_ctx(-1);
};

sub _init_zmq3_ffi {
    my $self = shift;

    my $soname = $self->soname;

    $zmq_ctx_new = FFI::Raw->new(
        $soname => 'zmq_ctx_new',
        FFI::Raw::ptr, # returns ctx ptr
        # void
    );

    $zmq_ctx_set = FFI::Raw->new(
        $soname => 'zmq_ctx_set',
        FFI::Raw::int, # error code,
        FFI::Raw::ptr, # ctx
        FFI::Raw::int, # opt constant
        FFI::Raw::int  # opt value
    );

    $zmq_ctx_get = FFI::Raw->new(
        $soname => 'zmq_ctx_get',
        FFI::Raw::int, # opt value,
        FFI::Raw::ptr, # ctx
        FFI::Raw::int  # opt constant
    );

    $zmq_ctx_destroy = FFI::Raw->new(
        $soname => 'zmq_ctx_destroy',
        FFI::Raw::int, # retval
        FFI::Raw::ptr  # ctx to destroy
    );
}

__PACKAGE__->meta->make_immutable();

