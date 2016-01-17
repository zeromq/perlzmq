package inc::SocketWrapperRole;

use Moo::Role;
use namespace::clean;

requires qw(
    connect_tt
    disconnect_tt
    bind_tt
    unbind_tt
    send_tt
    send_multipart_tt
    recv_tt
    recv_multipart_tt
    get_fd_tt
    get_linger_tt
    set_linger_tt
    get_identity_tt
    set_identity_tt
    subscribe_tt
    unsubscribe_tt
    has_pollin_tt
    has_pollout_tt
    get_tt
    set_tt
    close_tt
);

sub wrappers {
    my ($self) = @_;

    return {
        connect        => $self->connect_tt,
        disconnect     => $self->disconnect_tt,
        bind           => $self->bind_tt,
        unbind         => $self->unbind_tt,
        send           => $self->send_tt,
        send_multipart => $self->send_multipart_tt,
        recv           => $self->recv_tt,
        recv_multipart => $self->recv_multipart_tt,
        get_fd         => $self->get_fd_tt,
        get_linger     => $self->get_linger_tt,
        set_linger     => $self->set_linger_tt,
        get_identity   => $self->get_identity_tt,
        set_identity   => $self->set_identity_tt,
        subscribe      => $self->subscribe_tt,
        unsubscribe    => $self->unsubscribe_tt,
        has_pollin     => $self->has_pollin_tt,
        has_pollout    => $self->has_pollout_tt,
        get            => $self->get_tt,
        set            => $self->set_tt,
        close          => $self->close_tt,
    }
}

1;
