package ZMQ::FFI;

use Moo;
use namespace::autoclean;

use FFI::Raw;

use ZMQ::FFI::Socket;
use ZMQ::FFI::Util qw(zcheck_error zcheck_null);

has threads => (
    is        => 'ro',
    predicate => 'has_threads',
);

has max_sockets => (
    is        => 'ro',
    predicate => 'has_max_sockets',
);

has _ctx => (
    is => 'rw',
);

my $zmq_ctx_new = FFI::Raw->new(
    'libzmq.so',
    'zmq_ctx_new',
    FFI::Raw::ptr,
);

my $zmq_ctx_destroy = FFI::Raw->new(
    'libzmq.so',
    'zmq_ctx_destroy',
    FFI::Raw::int,
    FFI::Raw::ptr
);

sub BUILD {
    my $self = shift;

    $self->_ctx( $zmq_ctx_new->() );

    zcheck_null('zmq_ctx_new', $self->_ctx);
}

sub socket {
    my ($self, $type) = @_;

    return ZMQ::FFI::Socket->new( ctx => $self->_ctx, type => $type );
}

sub destroy {
    zcheck_error( 'zmq_ctx_destroy', $zmq_ctx_destroy->($self->_ctx) );
};

sub DEMOLISH {
    shift->destroy();
}

__PACKAGE__->meta->make_immutable();
