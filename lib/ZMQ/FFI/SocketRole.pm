package ZMQ::FFI::SocketRole;

use FFI::Platypus;

use Moo::Role;

has soname => (
    is       => 'ro',
    required => 1,
);

# context to associate socket instance with.
# reference necessary to guard against premature object destruction
has ctx => (
    is       => 'ro',
    required => 1,
);

# zmq constant socket type, e.g. ZMQ_REQ
has type => (
    is       => 'ro',
    required => 1,
);

# real underlying zmq socket pointer
has _socket => (
    is      => 'rw',
    default => -1,
);

# used to make sure we handle fork situations correctly
has _pid => (
    is      => 'ro',
    default => $$,
);

has sockopt_sizes => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_sockopt_sizes'
);

sub _build_sockopt_sizes {
    my $ffi = FFI::Platypus->new();

    return {
        int    => $ffi->sizeof('int'),
        sint64 => $ffi->sizeof('sint64'),
        uint64 => $ffi->sizeof('uint64'),
    };
}

requires qw(
    connect
    disconnect
    bind
    unbind
    send
    send_multipart
    recv
    recv_multipart
    get_fd
    get_linger
    set_linger
    get_identity
    set_identity
    subscribe
    unsubscribe
    has_pollin
    has_pollout
    get
    set
    close
);

1;
