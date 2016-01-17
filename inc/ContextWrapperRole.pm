package inc::ContextWrapperRole;

use Moo::Role;
use namespace::clean;

requires qw(
    init_tt
    get_tt
    set_tt
    socket_tt
    proxy_tt
    device_tt
    destroy_tt
);

sub wrappers {
    my ($self) = @_;

    return {
        init    => $self->init_tt,
        get     => $self->get_tt,
        set     => $self->set_tt,
        socket  => $self->socket_tt,
        proxy   => $self->proxy_tt,
        device  => $self->device_tt,
        destroy => $self->destroy_tt,
    }
}

1;
