package ZMQ::FFI::ZMQ2::Socket;

use Moo;
use namespace::autoclean;

use FFI::Raw;

extends q(ZMQ::FFI::SocketBase);

with q(ZMQ::FFI::SocketRole);

# ffi functions
my $zmq_msg_init;
my $zmq_msg_init_size;
my $zmq_msg_data;
my $zmq_msg_close;
my $zmq_msg_size;
my $zmq_send;
my $zmq_recv;
my $memcpy;

sub BUILD {
    shift->_init_zmq2_ffi();
}

sub send {
    my ($self, $msg, $flags) = @_;

    $flags //= 0;

    my $bytes_size = length($msg);
    my $bytes      = pack "a$bytes_size", $msg;
    my $bytes_ptr  = unpack('L!', pack('P', $bytes));

    my $msg_ptr = FFI::Raw::memptr(40); # large enough to hold zmq_msg_t

    $self->check_error(
        'zmq_msg_init_size',
        $zmq_msg_init_size->($msg_ptr, $bytes_size)
    );

    my $msg_data_ptr = $zmq_msg_data->($msg_ptr);
    $memcpy->($msg_data_ptr, $bytes_ptr, $bytes_size);

    $self->check_error(
        'zmq_send',
        $zmq_send->($self->_socket, $msg_ptr, $flags)
    );

    $zmq_msg_close->($msg_ptr);
}

sub recv {
    my ($self, $flags) = @_;

    $flags //= 0;

    my $msg_ptr = FFI::Raw::memptr(40);

    $self->check_error(
        'zmq_msg_init',
        $zmq_msg_init->($msg_ptr)
    );

    $self->check_error(
        'zmq_recv',
        $zmq_recv->($self->_socket, $msg_ptr, $flags)
    );

    my $data_ptr = $zmq_msg_data->($msg_ptr);

    my $msg_size = $zmq_msg_size->($msg_ptr);
    $self->check_error('zmq_msg_size', $msg_size);

    my $content_ptr = FFI::Raw::memptr($msg_size);

    $memcpy->($content_ptr, $data_ptr, $msg_size);

    $zmq_msg_close->($msg_ptr);
    return $content_ptr->tostr($msg_size);
}

sub _init_zmq2_ffi {
    my $self = shift;

    my $soname = $self->soname;

    $zmq_msg_init = FFI::Raw->new(
        $soname => 'zmq_msg_init',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # zmq_msg_t ptr
    );

    $zmq_msg_init_size = FFI::Raw->new(
        $soname => 'zmq_msg_init_size',
        FFI::Raw::int,
        FFI::Raw::ptr,
        FFI::Raw::int
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

    $zmq_msg_size = FFI::Raw->new(
        $soname => 'zmq_msg_size',
        FFI::Raw::int, # returns msg size in bytes
        FFI::Raw::ptr  # msg ptr
    );

    $zmq_send = FFI::Raw->new(
        $soname => 'zmq_send',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # socket
        FFI::Raw::ptr, # ptr to zmq_msg_t
        FFI::Raw::int  # flags
    );

    $zmq_recv = FFI::Raw->new(
        $soname => 'zmq_recv',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # socket ptr
        FFI::Raw::ptr, # msg ptr
        FFI::Raw::int  # flags
    );

    $memcpy = FFI::Raw->new(
        'libc.so.6' => 'memcpy',
        FFI::Raw::ptr,  # dest filled
        FFI::Raw::ptr,  # dest buf
        FFI::Raw::ptr,  # src
        FFI::Raw::int   # buf size
    );
}

__PACKAGE__->meta->make_immutable();

