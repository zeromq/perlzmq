package inc::ZMQ3::SocketWrappers;

use Moo;
use namespace::clean;

extends 'inc::ZMQ2::SocketWrappers';

#
# for zmq wrappers below that are hot spots (e.g. send/recv) we sacrifice
# readability for performance (by for example not assigning method params
# to local variables)
#

sub disconnect_tt {q(
sub disconnect {
    my ($self, $endpoint) = @_;

    [% closed_socket_check %]

    unless ($endpoint) {
        croak 'usage: $socket->disconnect($endpoint)';
    }

    $self->check_error(
        'zmq_disconnect',
        zmq_disconnect($self->socket_ptr, $endpoint)
    );
}
)}

sub unbind_tt {q(
sub unbind {
    my ($self, $endpoint) = @_;

    [% closed_socket_check %]

    unless ($endpoint) {
        croak 'usage: $socket->unbind($endpoint)';
    }

    $self->check_error(
        'zmq_unbind',
        zmq_unbind($self->socket_ptr, $endpoint)
    );
}
)}

sub send_tt {q(
sub send {
    # 0: self
    # 1: data
    # 2: flags

    [% closed_socket_check %]

    $_[0]->{last_errno} = 0;

    use bytes;
    my $length = length($_[1]);
    no bytes;

    if ( -1 == zmq_send($_[0]->socket_ptr, $_[1], $length, ($_[2] // 0)) ) {
        $_[0]->{last_errno} = zmq_errno();

        if ($_[0]->die_on_error) {
            $_[0]->fatal('zmq_send');
        }

        return;
    }
}
)}

sub recv_tt {q(
sub recv {
    # 0: self
    # 1: flags

    [% closed_socket_check %]

    $_[0]->{last_errno} = 0;

    # retval = msg size
    my $retval = zmq_msg_recv($_[0]->{"_zmq_msg_t"}, $_[0]->socket_ptr, $_[1] // 0);

    if ( $retval == -1 ) {
        $_[0]->{last_errno} = zmq_errno();

        if ($_[0]->die_on_error) {
            $_[0]->fatal('zmq_msg_recv');
        }


        return;
    }

    if ($retval) {
        return buffer_to_scalar(zmq_msg_data($_[0]->{"_zmq_msg_t"}), $retval);
    }

    return '';
}
)}

1;
