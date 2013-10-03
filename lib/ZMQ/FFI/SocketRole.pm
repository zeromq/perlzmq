package ZMQ::FFI::SocketRole;

use Moo::Role;

use FFI::Raw;

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

requires qw(
    connect
    bind
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

sub DEMOLISH {
    shift->close();
}

1;
