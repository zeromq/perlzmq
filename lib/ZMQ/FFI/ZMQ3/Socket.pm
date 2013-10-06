package ZMQ::FFI::ZMQ3::Socket;

use Moose;
use namespace::autoclean;

use FFI::Raw;

extends q(ZMQ::FFI::SocketBase);

with q(ZMQ::FFI::SocketRole);

# ffi functions
my $zmq_msg_init;
my $zmq_msg_data;
my $zmq_msg_close;
my $zmq_send;
my $zmq_msg_recv;
my $memcpy;

sub BUILD {
    shift->_init_zmq3_ffi();
}

sub send {
    my ($self, $msg, $flags) = @_;

    $flags //= 0;

    zcheck_error(
        'zmq_send',
        $zmq_send->($self->_socket, $msg, length($msg), $flags)
    );
}

sub recv {
    my ($self, $flags) = @_;

    $flags //= 0;

    my $msg_ptr = FFI::Raw::memptr(40); # large enough to hold zmq_msg_t

    zcheck_error('zmq_msg_init', $zmq_msg_init->($msg_ptr));

    my $msg_size = $zmq_msg_recv->($msg_ptr, $self->_socket, $flags);
    zcheck_error('zmq_msg_recv', $msg_size);

    my $data_ptr    = $zmq_msg_data->($msg_ptr);
    my $content_ptr = FFI::Raw::memptr($msg_size);

    $memcpy->($content_ptr, $data_ptr, $msg_size);
    $zmq_msg_close->($msg_ptr);

    return $content_ptr->tostr($msg_size);
}

sub _init_zmq3_ffi {
    my $soname = zmq_soname();

    $zmq_msg_init = FFI::Raw->new(
        $soname => 'zmq_msg_init',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # zmq_msg_t ptr
    );

    $zmq_msg_data = FFI::Raw->new(
        $soname => 'zmq_msg_data',
        FFI::Raw::ptr, # msg data ptr
        FFI::Raw::ptr  # msg ptr
    );

    $zmq_msg_close = FFI::Raw->new(
        $soname => 'zmq_msg_data',
        FFI::Raw::int, # retval
        FFI::Raw::ptr  # msg ptr
    );

    $zmq_send = FFI::Raw->new(
        $soname => 'zmq_send',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # socket
        FFI::Raw::str, # message
        FFI::Raw::int, # length
        FFI::Raw::int  # flags
    );

    $zmq_msg_recv = FFI::Raw->new(
        $soname => 'zmq_msg_recv',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # msg ptr
        FFI::Raw::ptr, # socket
        FFI::Raw::int  # flags
    );

    $memcpy = FFI::Raw->new(
        'libc.so.6',
        'memcpy',
        FFI::Raw::ptr,  # dest filled
        FFI::Raw::ptr,  # dest buf
        FFI::Raw::ptr,  # src
        FFI::Raw::int   # buf size
    );
}

__PACKAGE__->meta->make_immutable();

