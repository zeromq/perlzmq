package ZMQ::FFI::Socket;

use Moo;
use namespace::autoclean;

no if $] >= 5.018, warnings => "experimental";
use feature 'switch';

use FFI::Raw;
use Carp;

use ZMQ::FFI::Util qw(zcheck_error zcheck_null);
use ZMQ::FFI::Constants qw(:all);

has ctx_ptr => (
    is       => 'ro',
    required => 1,
);

has type => (
    is       => 'ro',
    required => 1,
);

has _socket => (
    is => 'rw',
);

my $zmq_socket = FFI::Raw->new(
    'libzmq.so' => 'zmq_socket',
    FFI::Raw::ptr, # returns socket ptr
    FFI::Raw::ptr, # takes ctx ptr
    FFI::Raw::int  # socket type
);

my $zmq_getsockopt = FFI::Raw->new(
    'libzmq.so' => 'zmq_getsockopt',
    FFI::Raw::int, # retval
    FFI::Raw::ptr, # socket ptr,
    FFI::Raw::int, # option constant
    FFI::Raw::ptr, # buf for option value
    FFI::Raw::ptr  # buf for size of option value
);

my $int_zmq_setsockopt = FFI::Raw->new(
    'libzmq.so' => 'zmq_setsockopt',
    FFI::Raw::int, # retval
    FFI::Raw::ptr, # socket ptr,
    FFI::Raw::int, # option constant
    FFI::Raw::ptr, # ptr to value int
    FFI::Raw::int  # size of option value
);

my $str_zmq_setsockopt = FFI::Raw->new(
    'libzmq.so' => 'zmq_setsockopt',
    FFI::Raw::int, # retval
    FFI::Raw::ptr, # socket ptr,
    FFI::Raw::int, # option constant
    FFI::Raw::str, # ptr to value string
    FFI::Raw::int  # size of option value
);

my $zmq_connect = FFI::Raw->new(
    'libzmq.so',
    'zmq_connect',
    FFI::Raw::int,
    FFI::Raw::ptr,
    FFI::Raw::str
);

my $zmq_bind = FFI::Raw->new(
    'libzmq.so',
    'zmq_bind',
    FFI::Raw::int,
    FFI::Raw::ptr,
    FFI::Raw::str
);

my $zmq_send = FFI::Raw->new(
    'libzmq.so',
    'zmq_send',
    FFI::Raw::int, # retval
    FFI::Raw::ptr, # socket
    FFI::Raw::str, # message
    FFI::Raw::int, # length
    FFI::Raw::int  # flags
);

my $zmq_msg_init = FFI::Raw->new(
    'libzmq.so',
    'zmq_msg_init',
    FFI::Raw::int, # retval
    FFI::Raw::ptr, # zmq_msg_t ptr
);

my $zmq_msg_recv = FFI::Raw->new(
    'libzmq.so',
    'zmq_msg_recv',
    FFI::Raw::int, # retval
    FFI::Raw::ptr, # msg ptr
    FFI::Raw::ptr, # socket
    FFI::Raw::int  # flags
);

my $zmq_msg_data = FFI::Raw->new(
    'libzmq.so',
    'zmq_msg_data',
    FFI::Raw::ptr, # msg data ptr
    FFI::Raw::ptr  # msg ptr
);

my $zmq_msg_close = FFI::Raw->new(
    'libzmq.so',
    'zmq_msg_data',
    FFI::Raw::int, # retval
    FFI::Raw::ptr  # msg ptr
);

my $zmq_close = FFI::Raw->new(
    'libzmq.so',
    'zmq_close',
    FFI::Raw::int,
    FFI::Raw::ptr,
);

my $memcpy = FFI::Raw->new(
    'libc.so.6',
    'memcpy',
    FFI::Raw::ptr,  # dest filled
    FFI::Raw::ptr,  # dest buf
    FFI::Raw::ptr,  # src
    FFI::Raw::int   # buf size
);

sub BUILD {
    my $self = shift;

    $self->_socket( $zmq_socket->($self->ctx_ptr, $self->type) );

    zcheck_null('zmq_socket', $self->_socket);

    # ensure clean edge state
    while ( $self->has_pollin ) {
        $self->recv();
    }
}

sub connect {
    my ($self, $endpoint) = @_;

    unless ($endpoint) {
        croak 'usage: $socket->connect($endpoint)'
    }

    zcheck_error('zmq_connect', $zmq_connect->($self->_socket, $endpoint));
}

sub bind {
    my ($self, $endpoint) = @_;

    unless ($endpoint) {
        croak 'usage: $socket->bind($endpoint)'
    }

    zcheck_error('zmq_bind', $zmq_bind->($self->_socket, $endpoint));
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

sub get_fd {
    my $self = shift;

    return $self->get(ZMQ_FD, 'int');
}

sub set_linger {
    my ($self, $linger) = @_;

    $self->set(ZMQ_LINGER, 'int', $linger);
}

sub get_linger {
    return shift->get(ZMQ_LINGER, 'int');
}

sub set_identity {
    my ($self, $id) = @_;

    $self->set(ZMQ_IDENTITY, 'binary', $id);
}

sub get_identity {
    return shift->get(ZMQ_IDENTITY, 'binary');
}

#sub subscribe {
#}

#sub unsubscribe {
#}

sub has_pollin {
    my $self = shift;

    my $zmq_events = $self->get(ZMQ_EVENTS, 'int');
    return $zmq_events & ZMQ_POLLIN;
}

sub has_pollout {
    my $self = shift;

    my $zmq_events = $self->get(ZMQ_EVENTS, 'int');
    return $zmq_events & ZMQ_POLLOUT;
}

sub get {
    my ($self, $opt, $opt_type) = @_;

    my $pack_type = $self->_get_pack_type($opt_type);

    my $optval     = pack $pack_type, 0;
    my $optval_len = pack 'L!', length($optval);

    my $sizeof_ptr     = length(pack('L!'));

    my $optval_ptr;
    if ($opt_type eq 'binary') {
        $optval_ptr = FFI::Raw::memptr($sizeof_ptr);
    }
    else {
        $optval_ptr = unpack('L!', pack('P', $optval));
    }

    my $optval_len_ptr = unpack('L!', pack('P', $optval_len));

    zcheck_error(
        'zmq_getsockopt',
        $zmq_getsockopt->(
            $self->_socket,
            $opt,
            $optval_ptr,
            $optval_len_ptr
        )
    );

    if ($opt_type eq 'binary') {
        $optval_len = unpack 'L!', $optval_len;

        if ($optval_len == 0) {
            return;
        }

        $optval = $optval_ptr->tostr($optval_len);
    }
    else {
        $optval = unpack $pack_type, $optval;
    }

    return $optval;
}

sub set {
    my ($self, $opt, $opt_type, $opt_val) = @_;

    if ($opt_type eq 'binary') {
        zcheck_error(
            'zmq_setsockopt',
            $str_zmq_setsockopt->(
                $self->_socket,
                $opt,
                $opt_val,
                length($opt_val)
            )
        );
    }
    else {
        my $pack_type = $self->_get_pack_type($opt_type);
        my $packed    = pack $pack_type, $opt_val;

        my $opt_ptr   = unpack('L!', pack('P', $packed));
        my $opt_len   = length(pack($pack_type, 0));

        zcheck_error(
            'zmq_setsockopt',
            $int_zmq_setsockopt->(
                $self->_socket,
                $opt,
                $opt_ptr,
                $opt_len
            )
        );
    }
}

sub _get_pack_type {
    my ($self, $zmqtype) = @_;

    given ($zmqtype) {
        when (/^int$/)      { return 'i!' }
        when (/^int64_t$/)  { return 'l!' }
        when (/^uint64_t$/) { return 'L!' }
        when (/^binary$/)   { return 'L!' }

        default { croak "unsupported type '$zmqtype'" }
    }
}

sub close {
    my $self = shift;

    zcheck_error('zmq_close', $zmq_close->($self->_socket));
}

sub DEMOLISH {
    shift->close();
}

__PACKAGE__->meta->make_immutable();
