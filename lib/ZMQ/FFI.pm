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
        $self->set_threads($self->_threads);
    }

    if ( $self->has_max_sockets ) {
        $self->set_max_sockets($self->_max_sockets);
    }

    zcheck_null('zmq_ctx_new', $self->_ctx);
}

sub set_threads {
    my ($self, $thread_count) = @_;

    zcheck_error(
        'zmq_ctx_set',
        $zmq_ctx_set->($self->_ctx, ZMQ_IO_THREADS, $thread_count)
    );
}

sub get_threads {
    my $self = shift;

    my $threads = $zmq_ctx_get->($self->_ctx, ZMQ_IO_THREADS);
    zcheck_error('zmq_ctx_get', $threads);

    return $threads;
}

sub set_max_sockets {
    my ($self, $socket_count) = @_;

    zcheck_error(
        'zmq_ctx_set',
        $zmq_ctx_set->($self->_ctx, ZMQ_MAX_SOCKETS, $socket_count)
    );
}

sub get_max_sockets {
    my $self = shift;

    my $max_sockets = $zmq_ctx_get->($self->_ctx, ZMQ_MAX_SOCKETS);
    zcheck_error('zmq_ctx_get', $max_sockets);

    return $max_sockets;
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
