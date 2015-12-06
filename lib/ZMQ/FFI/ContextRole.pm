package ZMQ::FFI::ContextRole;

use Moo::Role;

use ZMQ::FFI::Util qw(current_tid);

# real underlying zmq context pointer
has context_ptr => (
    is      => 'rw',
    default => -1,
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

has soname => (
    is       => 'ro',
    required => 1,
);

has threads => (
    is        => 'ro',
    predicate => 'has_threads',
);

has max_sockets => (
    is        => 'ro',
    predicate => 'has_max_sockets',
);

has sockets => (
    is        => 'rw',
    lazy      => 1,
    default   => sub { [] },
);

requires qw(
    get
    set
    socket
    proxy
    device
    destroy
);

1;
