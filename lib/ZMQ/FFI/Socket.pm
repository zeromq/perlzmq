package ZMQ::FFI::Socket;

use Moo;
use namespace::autoclean;

use FFI::Raw;

use ZMQ::FFI::Util qw(check_zerror check_znull);

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

    check_znull('zmq_socket', $self->_socket);
}

sub connect {
    my ($self, $endpoint) = @_;

    check_zerror('zmq_connect', $zmq_connect->($endpoint));
}

sub bind {
    my ($self, $endpoint) = @_;

    check_zerror('zmq_bind', $zmq_bind->($endpoint));
}

sub close {
    check_zerror($zmq_close->($self->_socket));
}

sub DEMOLISH {
    shift->close();
}

__PACKAGE__->meta->make_immutable();
