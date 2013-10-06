package ZMQ::FFI::ContextRole;

use Moose::Role;
use ZMQ::FFI::Util qw(zmq_version);
use ZMQ::FFI::ErrorHandler;

has _ctx => (
    is      => 'rw',
    default => -1,
);

# this is better composed as a role,
# but need to work around a bug in Moo
has _err_handler => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return ZMQ::FFI::ErrorHandler->new(
            soname => shift->soname
        );
    },
    handles => [qw(
        check_error
        check_null
    )],
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

has soname => (
    is       => 'ro',
    required => 1,
);

has version => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_version',
);

sub _build_version {
    my $self = shift;

    return join '.', zmq_version($self->soname);
}

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
