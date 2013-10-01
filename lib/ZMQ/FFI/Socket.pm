package ZMQ::FFI::Socket;

use Moo;
use namespace::autoclean;

use FFI::Raw;

use ZMQ::FFI::Util qw(zcheck_error zcheck_null);

has ctx => (
    is => 'ro',
);

has type => (
    is => 'ro',
);

has _socket => (
    is => 'rw',
);

my $zmq_socket = FFI::Raw->new(
    'libzmq.so',
    'zmq_socket',
    FFI::Raw::ptr,
    FFI::Raw::ptr,
    FFI::Raw::int
);

my $zmq_connect = FFI::Raw->new(
    'libzmq.so',
    'zmq_connect',
    FFI::Raw::int,
    FFI::Raw::ptr,
    FFI::Raw::str
);

my $zmq_bind = FFI::Raw->new(
    'libzmq.so',
    'zmq_bind',
    FFI::Raw::int,
    FFI::Raw::ptr,
    FFI::Raw::str
);

my $zmq_close = FFI::Raw->new(
    'libzmq.so',
    'zmq_close',
    FFI::Raw::int,
    FFI::Raw::ptr,
);

sub BUILD {
    my $self = shift;

    $zmq_socket->($self->ctx, $self->type);

    zcheck_null('zmq_socket', $self->_socket);
}

sub connect {
    my ($self, $endpoint) = @_;

    zcheck_error('zmq_connect', $zmq_connect->($endpoint));
}

sub bind {
    my ($self, $endpoint) = @_;

    zcheck_error('zmq_bind', $zmq_bind->($endpoint));
}

sub close {
    zcheck_error($zmq_close->($self->_socket));
}

sub DEMOLISH {
    shift->close();
}

__PACKAGE__->meta->make_immutable();
