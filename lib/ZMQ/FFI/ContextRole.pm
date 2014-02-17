package ZMQ::FFI::ContextRole;

use Moo::Role;

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
    destroy
);

1;
