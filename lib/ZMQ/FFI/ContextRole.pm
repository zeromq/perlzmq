package ZMQ::FFI::ContextRole;

use Moo::Role;

# real underlying zmq ctx pointer
has _ctx => (
    is      => 'rw',
    default => -1,
);

# used to make sure we handle fork situations correctly
has _pid => (
    is      => 'ro',
    default => sub { $$ },
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

requires qw(
    get
    set
    socket
    proxy
    device
    destroy
);

1;
