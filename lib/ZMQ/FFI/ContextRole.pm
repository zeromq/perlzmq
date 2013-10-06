package ZMQ::FFI::ContextRole;

use Moo::Role;
use ZMQ::FFI::ErrorHandler;
use ZMQ::FFI::Versioner;

with q(ZMQ::FFI::SoWrapper);

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

sub DEMOLISH {
    my $self = shift;

    unless ($self->_ctx == -1) {
        $self->destroy();
    }
}

1;
