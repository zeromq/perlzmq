package ZMQ::FFI::SocketRole;

use FFI::Platypus;
use FFI::Platypus::Memory qw(malloc);

use ZMQ::FFI::Constants qw(zmq_msg_t_size);
use ZMQ::FFI::Util qw(current_tid zmq_version);

use Moo::Role;

has soname => (
    is       => 'ro',
    required => 1,
);

# zmq constant socket type, e.g. ZMQ_REQ
has type => (
    is       => 'ro',
    required => 1,
);

# real underlying zmq socket pointer
has socket_ptr => (
    is      => 'rw',
    default => -1,
);

# a weak reference to the context object
has context => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

# message struct to reuse when sending/receiving
has _zmq_msg_t => (
    is        => 'ro',
    lazy      => 1,
    builder   => '_build_zmq_msg_t',
);

# used to make sure we handle fork situations correctly
has _pid => (
    is      => 'ro',
    default => sub { $$ },
);

# used to make sure we handle thread situations correctly
has _tid => (
    is      => 'ro',
    default => sub { current_tid() },
);

has sockopt_sizes => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_sockopt_sizes'
);

has event_size => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_event_size'
);

sub _build_zmq_msg_t {
    my ($self) = @_;

    my $msg_ptr;
    {
        no strict q/refs/;
        my $class = ref $self;
        $msg_ptr = malloc(zmq_msg_t_size);
        &{"$class\::zmq_msg_init"}($msg_ptr);
    }

    return $msg_ptr;
}

sub _build_sockopt_sizes {
    my $ffi = FFI::Platypus->new();

    return {
        int    => $ffi->sizeof('int'),
        sint64 => $ffi->sizeof('sint64'),
        uint64 => $ffi->sizeof('uint64'),
    };
}

sub _build_event_size {
    my $ffi = FFI::Platypus->new();

    my ($major, $minor, $patch) = zmq_version();

    my $size;

    if ($major == 3) {
        $size = $ffi->sizeof('int') * 2 + $ffi->sizeof('opaque');
    }
    elsif ($major > 3) {
        $size = $ffi->sizeof('uint16', 'sint32');
    }

    return $size;
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
    monitor
    recv_event
);

1;
