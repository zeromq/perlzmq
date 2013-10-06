package ZMQ::FFI::ContextRole;

use Moo::Role;
use ZMQ::FFI::ErrorHandler;
use ZMQ::FFI::Versioner;

has _ctx => (
    is      => 'rw',
    default => -1,
);

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

has _versioner => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return ZMQ::FFI::Versioner->new(
            soname => shift->soname
        );
    },
    handles => [qw(version)],
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
