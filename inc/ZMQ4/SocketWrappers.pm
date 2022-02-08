package inc::ZMQ4::SocketWrappers;

use Moo;
use namespace::clean;

extends 'inc::ZMQ3::SocketWrappers';

sub recv_event_tt {q(
sub recv_event {
    my ($self, $flags) = @_;

    [% closed_socket_check %]

    my ($event, $endpoint) = $self->recv_multipart($flags);

    my ($id, $value) = unpack('S L', $event);

    return ($id, $value, $endpoint);
}
)}

1;
