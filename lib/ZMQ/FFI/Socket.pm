package ZMQ::FFI::Socket;

use Moo;
use namespace::autoclean;

use FFI::Raw;
use Carp;

use ZMQ::FFI::Util qw(zcheck_error zcheck_null);
use ZMQ::Constants qw(ZMQ_FD ZMQ_EVENTS ZMQ_POLLIN);

has ctx_ptr => (
    is       => 'ro',
    required => 1,
);

has type => (
    is       => 'ro',
    required => 1,
);

has _socket => (
    is => 'rw',
);

my $zmq_socket = FFI::Raw->new(
    'libzmq.so' => 'zmq_socket',
    FFI::Raw::ptr, # returns socket ptr
    FFI::Raw::ptr, # takes ctx ptr
    FFI::Raw::int  # socket type
);

my $zmq_getsockopt = FFI::Raw->new(
    'libzmq.so' => 'zmq_getsockopt',
    FFI::Raw::int, # retval
    FFI::Raw::ptr, # socket ptr,
    FFI::Raw::int, # option constant
    FFI::Raw::ptr, # buf for option value
    FFI::Raw::ptr  # buf for size of option value
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

my $zmq_send = FFI::Raw->new(
    'libzmq.so',
    'zmq_send',
    FFI::Raw::int, # retval
    FFI::Raw::ptr, # socket
    FFI::Raw::str, # message
    FFI::Raw::int, # length
    FFI::Raw::int  # flags
);

my $zmq_msg_init = FFI::Raw->new(
    'libzmq.so',
    'zmq_msg_init',
    FFI::Raw::int, # retval
    FFI::Raw::ptr, # zmq_msg_t ptr
);

my $zmq_msg_recv = FFI::Raw->new(
    'libzmq.so',
    'zmq_msg_recv',
    FFI::Raw::int, # retval
    FFI::Raw::ptr, # msg ptr
    FFI::Raw::ptr, # socket
    FFI::Raw::int  # flags
);

my $zmq_msg_data = FFI::Raw->new(
    'libzmq.so',
    'zmq_msg_data',
    FFI::Raw::ptr, # msg data ptr
    FFI::Raw::ptr  # msg ptr
);

my $zmq_msg_close = FFI::Raw->new(
    'libzmq.so',
    'zmq_msg_data',
    FFI::Raw::int, # retval
    FFI::Raw::ptr  # msg ptr
);

my $zmq_close = FFI::Raw->new(
    'libzmq.so',
    'zmq_close',
    FFI::Raw::int,
    FFI::Raw::ptr,
);

my $memcpy = FFI::Raw->new(
    'libc.so.6',
    'memcpy',
    FFI::Raw::ptr,  # dest filled
    FFI::Raw::ptr,  # dest buf
    FFI::Raw::ptr,  # src
    FFI::Raw::int   # buf size
);

sub BUILD {
    my $self = shift;

    $self->_socket( $zmq_socket->($self->ctx_ptr, $self->type) );

    zcheck_null('zmq_socket', $self->_socket);

    # ensure clean edge state
    while ( $self->has_pollin ) {
        $self->recv();
    }
}

sub connect {
    my ($self, $endpoint) = @_;

    unless ($endpoint) {
        croak 'usage: $socket->connect($endpoint)'
    }

    zcheck_error('zmq_connect', $zmq_connect->($self->_socket, $endpoint));
}

sub bind {
    my ($self, $endpoint) = @_;

    unless ($endpoint) {
        croak 'usage: $socket->bind($endpoint)'
    }

    zcheck_error('zmq_bind', $zmq_bind->($self->_socket, $endpoint));
}

sub send {
    my ($self, $msg, $flags) = @_;

    $flags //= 0;

    zcheck_error(
        'zmq_send',
        $zmq_send->($self->_socket, $msg, length($msg), $flags)
    );
}

sub recv {
    my ($self, $flags) = @_;

    $flags //= 0;

    my $msg_ptr = FFI::Raw::memptr(40); # large enough to hold zmq_msg_t

    zcheck_error('zmq_msg_init', $zmq_msg_init->($msg_ptr));

    my $msg_size = $zmq_msg_recv->($msg_ptr, $self->_socket, $flags);
    zcheck_error('zmq_msg_recv', $msg_size);

    my $data_ptr    = $zmq_msg_data->($msg_ptr);
    my $content_ptr = FFI::Raw::memptr($msg_size);

    $memcpy->($content_ptr, $data_ptr, $msg_size);
    $zmq_msg_close->($msg_ptr);

    return $content_ptr->tostr($msg_size);
}

sub get_fd {
    my $self = shift;

    my $fd     = pack 'I!', 0;
    my $fd_len = pack 'L!', length($fd);

    my $fd_ptr     = unpack('L!', pack('P', $fd));
    my $fd_len_ptr = unpack('L!', pack('P', $fd_len));

    zcheck_error(
        'zmq_getsockopt',
        $zmq_getsockopt->(
            $self->_socket,
            ZMQ_FD,
            $fd_ptr,
            $fd_len_ptr
        )
    );

    $fd = unpack 'I!', $fd;
    return $fd;
}

sub has_pollin {
    my $self = shift;

    my $zmq_events = pack 'I!', 0;
    my $ze_len     = pack 'L!', length($zmq_events);

    my $ze_ptr     = unpack('L!', pack('P', $zmq_events));
    my $ze_len_ptr = unpack('L!', pack('P', $ze_len));


    zcheck_error(
        'zmq_getscokopt',
        $zmq_getsockopt->(
            $self->_socket,
            ZMQ_EVENTS,
            $ze_ptr,
            $ze_len_ptr
        )
    );

    $zmq_events = unpack 'I!', $zmq_events;
    return $zmq_events & ZMQ_POLLIN;
}

sub close {
    my $self = shift;

    zcheck_error('zmq_close', $zmq_close->($self->_socket));
}

sub DEMOLISH {
    shift->close();
}

__PACKAGE__->meta->make_immutable();
