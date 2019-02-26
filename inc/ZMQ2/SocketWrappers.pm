package inc::ZMQ2::SocketWrappers;

use Moo;
use namespace::clean;

with 'inc::SocketWrapperRole';

#
# for zmq wrappers below that are hot spots (e.g. send/recv) we sacrifice
# readability for performance (by for example not assigning method params
# to local variables)
#

sub connect_tt {q(
sub connect {
    my ($self, $endpoint) = @_;

    [% closed_socket_check %]

    unless ($endpoint) {
        croak 'usage: $socket->connect($endpoint)';
    }

    $self->check_error(
        'zmq_connect',
        zmq_connect($self->socket_ptr, $endpoint)
    );
}
)}

sub disconnect_tt {q(
sub disconnect {
    my ($self) = @_;

    [% closed_socket_check %]

    $self->bad_version(
        $self->verstr,
        "disconnect not available in zmq 2.x"
    );
}
)}

sub bind_tt {q(
sub bind {
    my ($self, $endpoint) = @_;

    [% closed_socket_check %]

    unless ($endpoint) {
        croak 'usage: $socket->bind($endpoint)'
    }

    $self->check_error(
        'zmq_bind',
        zmq_bind($self->socket_ptr, $endpoint)
    );
}
)}

sub unbind_tt {q(
sub unbind {
    my ($self) = @_;

    [% closed_socket_check %]

    $self->bad_version(
        $self->verstr,
        "unbind not available in zmq 2.x"
    );
}
)}

sub send_tt {q(
sub send {
    # 0: self
    # 1: data
    # 2: flags

    [% closed_socket_check %]

    my $data_ptr;
    my $data_size;
    my $data = $_[1];

    $_[0]->{last_errno} = 0;

    use bytes;
    ($data_ptr, $data_size) = scalar_to_buffer($data);
    no bytes;

    if ( -1 == zmq_msg_init_size($_[0]->{"_zmq_msg_t"}, $data_size) ) {
        $_[0]->{last_errno} = zmq_errno();

        if ($_[0]->die_on_error) {
            $_[0]->fatal('zmq_msg_init_size');
        }

        return;
    }

    my $msg_data_ptr = zmq_msg_data($_[0]->{"_zmq_msg_t"});
    memcpy($msg_data_ptr, $data_ptr, $data_size);

    if ( -1 == zmq_send($_[0]->socket_ptr, $_[0]->{"_zmq_msg_t"}, $_[2] // 0) ) {
        $_[0]->{last_errno} = zmq_errno();

        if ($_[0]->die_on_error) {
            $_[0]->fatal('zmq_send');
        }

        return;
    }
}
)}

sub send_multipart_tt {q(
sub send_multipart {
    # 0: self
    # 1: partsref
    # 2: flags

    [% closed_socket_check %]

    my @parts = @{$_[1] // []};
    unless (@parts) {
        croak 'usage: send_multipart($parts, $flags)';
    }

    for my $i (0..$#parts-1) {
        $_[0]->send($parts[$i], ($_[2] // 0) | ZMQ_SNDMORE);

        # don't need to explicitly check die_on_error
        # since send would have exploded if it was true
        if ($_[0]->has_error) {
            return;
        }
    }

    $_[0]->send($parts[$#parts], $_[2] // 0);
}
)}

sub recv_tt {q(
sub recv {
    # 0: self
    # 1: flags

    [% closed_socket_check %]

    $_[0]->{last_errno} = 0;

    if ( -1 == zmq_recv($_[0]->socket_ptr, $_[0]->{"_zmq_msg_t"}, $_[1] // 0) ) {
        $_[0]->{last_errno} = zmq_errno();

        if ($_[0]->die_on_error) {
            $_[0]->fatal('zmq_recv');
        }

        return;
    }

    # retval = msg size
    my $retval = zmq_msg_size($_[0]->{"_zmq_msg_t"});

    if ($retval) {
        return buffer_to_scalar(zmq_msg_data($_[0]->{"_zmq_msg_t"}), $retval);
    }

    return '';
}
)}

sub recv_multipart_tt {q(
sub recv_multipart {
    # 0: self
    # 1: flags

    [% closed_socket_check %]

    my @parts = ( $_[0]->recv($_[1]) );

    if ($_[0]->has_error) {
        return;
    }

    my $type = ($_[0]->version)[0] == 2 ? 'int64_t' : 'int';

    while ( $_[0]->get(ZMQ_RCVMORE, $type) ){
        push @parts, $_[0]->recv($_[1] // 0);

        # don't need to explicitly check die_on_error
        # since recv would have exploded if it was true
        if ($_[0]->has_error) {
            return;
        }
    }

    return @parts;
}
)}

sub get_fd_tt {q(
sub get_fd {
    [% closed_socket_check %]

    return $_[0]->get(ZMQ_FD, 'int');
}
)}

sub get_linger_tt {q(
sub get_linger {
    [% closed_socket_check %]

    return $_[0]->get(ZMQ_LINGER, 'int');
}
)}

sub set_linger_tt {q(
sub set_linger {
    my ($self, $linger) = @_;

    [% closed_socket_check %]

    $self->set(ZMQ_LINGER, 'int', $linger);
}
)}

sub get_identity_tt {q(
sub get_identity {
    [% closed_socket_check %]

    return $_[0]->get(ZMQ_IDENTITY, 'binary');
}
)}

sub set_identity_tt {q(
sub set_identity {
    my ($self, $id) = @_;

    [% closed_socket_check %]

    $self->set(ZMQ_IDENTITY, 'binary', $id);
}
)}

sub subscribe_tt {q(
sub subscribe {
    my ($self, $topic) = @_;

    [% closed_socket_check %]

    $self->set(ZMQ_SUBSCRIBE, 'binary', $topic);
}
)}

sub unsubscribe_tt {q(
sub unsubscribe {
    my ($self, $topic) = @_;

    [% closed_socket_check %]

    $self->set(ZMQ_UNSUBSCRIBE, 'binary', $topic);
}
)}

sub has_pollin_tt {q(
sub has_pollin {
    [% closed_socket_check %]

    return $_[0]->get(ZMQ_EVENTS, 'int') & ZMQ_POLLIN;
}
)}

sub has_pollout_tt {q(
sub has_pollout {
    [% closed_socket_check %]

    return $_[0]->get(ZMQ_EVENTS, 'int') & ZMQ_POLLOUT;
}
)}

sub get_tt {q(
sub get {
    my ($self, $opt, $opt_type) = @_;

    [% closed_socket_check %]

    my $optval;
    my $optval_len;

    for ($opt_type) {
        when (/^(binary|string)$/) {
            # ZMQ_IDENTITY uses binary type and can be at most 255 bytes long
            #
            # ZMQ_LAST_ENDPOINT uses string type and expects a buffer large
            # enough to hold an endpoint string
            #
            # So for these cases 256 should be sufficient (including \0).
            # Other binary/string opts are being added all the time, and
            # hopefully this value scales, but we can always increase it if
            # necessary
            my $optval_ptr = malloc(256);
            $optval_len    = 256;

            $self->check_error(
                'zmq_getsockopt',
                zmq_getsockopt_binary(
                    $self->socket_ptr,
                    $opt,
                    $optval_ptr,
                    \$optval_len
                )
            );

            if ($self->has_error) {
                free($optval_ptr);
                return;
            }

            if ($opt_type eq 'binary') {
                $optval = buffer_to_scalar($optval_ptr, $optval_len);
                free($optval_ptr);
            }
            else { # string
                # FFI::Platypus already appends a null terminating byte for
                # strings, so strip the one included by zeromq (otherwise test
                # comparisons fail due to the extra NUL)
                $optval = buffer_to_scalar($optval_ptr, $optval_len-1);
                free($optval_ptr);
            }
        }

        when ('int') {
            $optval_len = $self->sockopt_sizes->{'int'};
            $self->check_error(
                'zmq_getsockopt',
                zmq_getsockopt_int(
                    $self->socket_ptr,
                    $opt,
                    \$optval,
                    \$optval_len
                )
            );
        }

        when ('int64_t') {
            $optval_len = $self->sockopt_sizes->{'sint64'};
            $self->check_error(
                'zmq_getsockopt',
                zmq_getsockopt_int64(
                    $self->socket_ptr,
                    $opt,
                    \$optval,
                    \$optval_len
                )
            );
        }

        when ('uint64_t') {
            $optval_len = $self->sockopt_sizes->{'uint64'};
            $self->check_error(
                'zmq_getsockopt',
                zmq_getsockopt_uint64(
                    $self->socket_ptr,
                    $opt,
                    \$optval,
                    \$optval_len
                )
            );
        }

        default {
            croak "unknown type $opt_type";
        }
    }

    if ($optval ne '') {
        return $optval;
    }

    return;
}
)}

sub set_tt {q(
sub set {
    my ($self, $opt, $opt_type, $optval) = @_;

    [% closed_socket_check %]

    for ($opt_type) {
        when (/^(binary|string)$/) {
            my ($optval_ptr, $optval_len) = scalar_to_buffer($optval);
            $self->check_error(
                'zmq_setsockopt',
                zmq_setsockopt_binary(
                    $self->socket_ptr,
                    $opt,
                    $optval_ptr,
                    $optval_len
                )
            );
        }

        when ('int') {
            $self->check_error(
                'zmq_setsockopt',
                zmq_setsockopt_int(
                    $self->socket_ptr,
                    $opt,
                    \$optval,
                    $self->sockopt_sizes->{'int'}
                )
            );
        }

        when ('int64_t') {
            $self->check_error(
                'zmq_setsockopt',
                zmq_setsockopt_int64(
                    $self->socket_ptr,
                    $opt,
                    \$optval,
                    $self->sockopt_sizes->{'sint64'}
                )
            );
        }

        when ('uint64_t') {
            $self->check_error(
                'zmq_setsockopt',
                zmq_setsockopt_uint64(
                    $self->socket_ptr,
                    $opt,
                    \$optval,
                    $self->sockopt_sizes->{'uint64'}
                )
            );
        }

        default {
            croak "unknown type $opt_type";
        }
    }

    return;
}
)}

sub close_tt {q(
sub close {
    my ($self) = @_;

    [% closed_socket_check %]

    # don't try to cleanup socket cloned from another thread
    return unless $self->_tid == current_tid();

    # don't try to cleanup socket copied from another process (fork)
    return unless $self->_pid == $$;

    $self->check_error(
        'zmq_msg_close',
        zmq_msg_close($self->_zmq_msg_t)
    );

    $self->check_error(
        'zmq_close',
        zmq_close($self->socket_ptr)
    );

    $self->socket_ptr(-1);
}
)}

1;
