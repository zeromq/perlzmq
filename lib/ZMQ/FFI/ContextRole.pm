package ZMQ::FFI::ContextRole;

use Moo::Role;
use ZMQ::FFI::Util qw(zmq_version);

has _ctx => (
    is      => 'rw',
    default => -1,
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
    my $self = shift;

    unless ($self->_ctx == -1) {
        $self->destroy();
    }
}

1;
