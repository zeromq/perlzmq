package ZMQ::FFI;

use Moo;
use namespace::autoclean;

use FFI::Raw;

use ZMQ::FFI::Socket;
use ZMQ::FFI::Util qw(zcheck_error zcheck_null);

use ZMQ::FFI::Constants qw(ZMQ_IO_THREADS ZMQ_MAX_SOCKETS);

has threads => (
    is        => 'ro',
    reader    => '_threads',
    predicate => 'has_threads',
);

has max_sockets => (
    is        => 'ro',
    reader    => '_max_sockets',
    predicate => 'has_max_sockets',
);

has _ctx => (
    is => 'rw',
);

my $zmq_ctx_new = FFI::Raw->new(
    'libzmq.so' => 'zmq_ctx_new',
    FFI::Raw::ptr, # returns ctx ptr
    # void
);

my $zmq_ctx_set = FFI::Raw->new(
    'libzmq.so' => 'zmq_ctx_set',
    FFI::Raw::int, # error code,
    FFI::Raw::ptr, # ctx
    FFI::Raw::int, # opt constant
    FFI::Raw::int  # opt value
);

my $zmq_ctx_get = FFI::Raw->new(
    'libzmq.so' => 'zmq_ctx_get',
    FFI::Raw::int, # opt value,
    FFI::Raw::ptr, # ctx
    FFI::Raw::int  # opt constant
);

my $zmq_ctx_destroy = FFI::Raw->new(
    'libzmq.so' => 'zmq_ctx_destroy',
    FFI::Raw::int, # retval
    FFI::Raw::ptr  # ctx to destroy
);

sub BUILD {
    my $self = shift;

    $self->_ctx( $zmq_ctx_new->() );

    if ( $self->has_threads ) {
        $self->set(ZMQ_IO_THREADS, $self->_threads);
    }

    if ( $self->has_max_sockets ) {
        $self->set(ZMQ_MAX_SOCKETS, $self->_max_sockets);
    }

    zcheck_null('zmq_ctx_new', $self->_ctx);
}

sub set {
    my ($self, $option, $option_val) = @_;

    zcheck_error(
        'zmq_ctx_set',
        $zmq_ctx_set->($self->_ctx, $option, $option_val)
    );
}

sub get {
    my ($self, $option) = @_;

    my $option_val = $zmq_ctx_get->($self->_ctx, $option);
    zcheck_error('zmq_ctx_get', $option_val);

    return $option_val;
}

sub socket {
    my ($self, $type) = @_;

    return ZMQ::FFI::Socket->new( ctx_ptr => $self->_ctx, type => $type );
}

sub destroy {
    my $self = shift;

    zcheck_error('zmq_ctx_destroy', $zmq_ctx_destroy->($self->_ctx));
};

sub DEMOLISH {
    shift->destroy();
}

__PACKAGE__->meta->make_immutable();
