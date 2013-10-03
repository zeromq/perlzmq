package ZMQ::FFI::ContextRole;

use Moo::Role;

has _ctx => (
    is => 'rw'
);

has threads => (
    is        => 'ro',
    reader    => '_threads',
    predicate => 'has_threads',
);

has max_sockets => (
    is        => 'ro',
    reader    => '_max_sockets',
    predicate => 'has_max_sockets',
);

requires qw(
    get
    set
    socket
    destroy
);

sub DEMOLISH {
    shift->destroy();
}

1;
