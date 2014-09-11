package ZMQ::FFI::ZMQ3::Socket;

use Moo;
use namespace::autoclean;

use Carp;
use FFI::Raw;

use ZMQ::FFI::Constants q(zmq_msg_t_size);

extends q(ZMQ::FFI::SocketBase);

has _zmq3_ffi => (
    is      => 'ro',
    lazy    => 1,
    builder => '_init_zmq3_ffi',
);

sub send {
    my ($self, $msg, $flags) = @_;

    $flags //= 0;

    my $length;
    {
        use bytes;
        $length = length($msg);
    };

    $self->check_error(
        'zmq_send',
        $self->_zmq3_ffi->{zmq_send}->(
            $self->_socket, $msg, $length, $flags
        )
    );
}

sub recv {
    my ($self, $flags) = @_;

    $flags //= 0;

    my $ffi = $self->_ffi;

    my $msg_ptr = FFI::Raw::memptr(zmq_msg_t_size);

    $self->check_error(
        'zmq_msg_init',
        $ffi->{zmq_msg_init}->($msg_ptr)
    );

    my $msg_size =
        $self->_zmq3_ffi->{zmq_msg_recv}->($msg_ptr, $self->_socket, $flags);

    $self->check_error('zmq_msg_recv', $msg_size);

    my $rv;
    if ($msg_size) {
        my $data_ptr    = $ffi->{zmq_msg_data}->($msg_ptr);
        my $content_ptr = FFI::Raw::memptr($msg_size);

        $ffi->{memcpy}->($content_ptr, $data_ptr, $msg_size);
        $rv = $content_ptr->tostr($msg_size);
    }
    else {
        $rv = '';
    }

    $ffi->{zmq_msg_close}->($msg_ptr);

    return $rv;
}

sub disconnect {
    my ($self, $endpoint) = @_;

    unless ($endpoint) {
        croak 'usage: $socket->disconnect($endpoint)';
    }

    $self->check_error(
        'zmq_disconnect',
        $self->_zmq3_ffi->{zmq_disconnect}->($self->_socket, $endpoint)
    );
}

sub unbind {
    my ($self, $endpoint) = @_;

    unless ($endpoint) {
        croak 'usage: $socket->unbind($endpoint)';
    }

    $self->check_error(
        'zmq_unbind',
        $self->_zmq3_ffi->{zmq_unbind}->($self->_socket, $endpoint)
    );
}

sub _init_zmq3_ffi {
    my $self = shift;

    my $ffi    = {};
    my $soname = $self->soname;

    $ffi->{zmq_send} = FFI::Raw->new(
        $soname => 'zmq_send',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # socket
        FFI::Raw::str, # message
        FFI::Raw::int, # length
        FFI::Raw::int  # flags
    );

    $ffi->{zmq_msg_recv} = FFI::Raw->new(
        $soname => 'zmq_msg_recv',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # msg ptr
        FFI::Raw::ptr, # socket
        FFI::Raw::int  # flags
    );

    $ffi->{zmq_unbind} = FFI::Raw->new(
        $soname => 'zmq_unbind',
        FFI::Raw::int,
        FFI::Raw::ptr,
        FFI::Raw::str
    );

    $ffi->{zmq_disconnect} = FFI::Raw->new(
        $soname => 'zmq_disconnect',
        FFI::Raw::int,
        FFI::Raw::ptr,
        FFI::Raw::str
    );

    return $ffi;
}

__PACKAGE__->meta->make_immutable();

