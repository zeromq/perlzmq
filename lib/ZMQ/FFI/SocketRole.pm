package ZMQ::FFI::SocketRole;

use FFI::Platypus;

use Moo::Role;

with qw(ZMQ::FFI::ErrorHandler);

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
    is       => 'rw',
    lazy     => 1,
    required => 1,
    builder  => '_build_socket',
);

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

sub _load_common_ffi {
    my ($soname) = @_;

    my $ffi   = FFI::Platypus->new( lib => $soname );
    my $class = caller;

    $ffi->attach(
        ['zmq_socket' => "${class}::zmq_socket"],
            => ['pointer', 'int'] => 'pointer'
    );

    $ffi->attach(
        ['zmq_getsockopt' => "${class}::zmq_getsockopt_binary"],
            => ['pointer', 'int', 'pointer', 'size_t*'] => 'int'
    );

    $ffi->attach(
        ['zmq_getsockopt' => "${class}::zmq_getsockopt_int"],
            => ['pointer', 'int', 'int*', 'size_t*'] => 'int'
    );

    $ffi->attach(
        ['zmq_getsockopt' => "${class}::zmq_getsockopt_int64"],
            => ['pointer', 'int', 'sint64*', 'size_t*'] => 'int'
    );

    $ffi->attach(
        ['zmq_getsockopt' => "${class}::zmq_getsockopt_uint64"],
            => ['pointer', 'int', 'uint64*', 'size_t*'] => 'int'
    );

    $ffi->attach(
        ['zmq_setsockopt' => "${class}::zmq_setsockopt_binary"],
            => ['pointer', 'int', 'pointer', 'size_t'] => 'int'
    );

    $ffi->attach(
        ['zmq_setsockopt' => "${class}::zmq_setsockopt_int"],
            => ['pointer', 'int', 'int*', 'size_t'] => 'int'
    );

    $ffi->attach(
        ['zmq_setsockopt' => "${class}::zmq_setsockopt_int64"],
            => ['pointer', 'int', 'sint64*', 'size_t'] => 'int'
    );

    $ffi->attach(
        ['zmq_setsockopt' => "${class}::zmq_setsockopt_uint64"],
            => ['pointer', 'int', 'uint64*', 'size_t'] => 'int'
    );

    $ffi->attach(
        ['zmq_connect' => "${class}::zmq_connect"],
            => ['pointer', 'string'] => 'int'
    );

    $ffi->attach(
        ['zmq_bind' => "${class}::zmq_bind"],
            => ['pointer', 'string'] => 'int'
    );

    $ffi->attach(
        ['zmq_msg_init' => "${class}::zmq_msg_init"],
            => ['pointer'] => 'int'
    );

    $ffi->attach(
        ['zmq_msg_init_size' => "${class}::zmq_msg_init_size"],
            => ['pointer', 'int'] => 'int'
    );

    $ffi->attach(
        ['zmq_msg_size' => "${class}::zmq_msg_size"],
            => ['pointer'] => 'int'
    );

    $ffi->attach(
        ['zmq_msg_data' => "${class}::zmq_msg_data"],
            => ['pointer'] => 'pointer'
    );

    $ffi->attach(
        ['zmq_msg_close' => "${class}::zmq_msg_close"],
            => ['pointer'] => 'int'
    );

    $ffi->attach(
        ['zmq_close' => "${class}::zmq_close"],
            => ['pointer'] => 'int'
    );
}

1;
