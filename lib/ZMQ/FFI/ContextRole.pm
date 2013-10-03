package ZMQ::FFI::ContextRole;

use Moo::Role;
use ZMQ::FFI::Util qw(zmq_version);

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

sub version {
    return join '.', zmq_version();
}

sub DEMOLISH {
    shift->destroy();
}

1;
