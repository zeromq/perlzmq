package ZMQ::FFI::SocketRole;

use Moose::Role;

use FFI::Raw;

has ctx_ptr => (
    is       => 'ro',
    required => 1,
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

has soname => (
    is       => 'ro',
    required => 1,
);

has type => (
    is       => 'ro',
    required => 1,
);

has _socket => (
    is      => 'rw',
    default => -1,
);

requires qw(
    connect
    bind
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
);

sub DEMOLISH {
    my $self = shift;

    unless ($self->_socket == -1) {
        $self->close();
    }
}

1;
