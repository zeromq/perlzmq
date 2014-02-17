package ZMQ::FFI::SocketBase;

use Moo;
use namespace::autoclean;

no if $] >= 5.018, warnings => "experimental";
use feature 'switch';

use Carp;
use FFI::Raw;
use Try::Tiny;

use Math::Int64 qw(
    int64_to_native  native_to_int64
    uint64_to_native native_to_uint64
);

use ZMQ::FFI::Constants qw(:all);

with qw(
    ZMQ::FFI::SocketRole
    ZMQ::FFI::ErrorHandler
    ZMQ::FFI::Versioner
);

has _ffi => (
    is => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_init_ffi',
);

# real underlying zmq ctx pointer
has _ctx => (
    is      => 'ro',
    lazy    => 1,
    default => sub { shift->ctx->_ctx },
);

# real underlying zmq socket pointer
has _socket => (
    is      => 'rw',
    default => -1,
);

sub BUILD {
    my $self = shift;

    $self->_socket( $self->_ffi->{zmq_socket}->($self->_ctx, $self->type) );

    try {
        $self->check_null('zmq_socket', $self->_socket);
    }
    catch {
        $self->_socket(-1);
        die $_;
    };

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

    $self->check_error(
        'zmq_connect',
        $self->_ffi->{zmq_connect}->($self->_socket, $endpoint)
    );
}

sub bind {
    my ($self, $endpoint) = @_;

    unless ($endpoint) {
        croak 'usage: $socket->bind($endpoint)'
    }

    $self->check_error(
        'zmq_bind',
        $self->_ffi->{zmq_bind}->($self->_socket, $endpoint)
    );
}

sub send {
    croak 'unimplemented in base class';
}

sub send_multipart {
    my ($self, $partsref, $flags) = @_;

    $flags //= 0;

    my @parts = @{$partsref // []};
    unless (@parts) {
        croak 'usage: send_multipart($parts, $flags)';
    }

    for my $i (0..$#parts-1) {
        $self->send($parts[$i], ZMQ_SNDMORE);
    }

    $self->send($parts[$#parts], $flags);
}

sub recv {
    croak 'unimplemented in base class';
}

sub recv_multipart {
    my ($self, $flags) = @_;

    my @parts = ( $self->recv($flags) );

    my ($major) = $self->version;
    my $type    = $major == 2 ? 'int64_t' : 'int';

    while ( $self->get(ZMQ_RCVMORE, $type) ){
        push @parts, $self->recv($flags);
    }

    return @parts;
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

sub subscribe {
    my ($self, $topic) = @_;

    $self->set(ZMQ_SUBSCRIBE, 'binary', $topic);
}

sub unsubscribe {
    my ($self, $topic) = @_;

    $self->set(ZMQ_UNSUBSCRIBE, 'binary', $topic);
}

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

    my $optval = $self->_pack($opt_type, 0);

    my $optval_len = pack 'L!', length($optval);
    my $sizeof_ptr = length(pack('L!'));

    my $optval_ptr =
        $opt_type eq 'binary' ?
            FFI::Raw::memptr($sizeof_ptr)
            : unpack('L!', pack('P', $optval))
            ;

    my $optval_len_ptr = unpack('L!', pack('P', $optval_len));

    $self->check_error(
        'zmq_getsockopt',
        $self->_ffi->{zmq_getsockopt}->(
            $self->_socket,
            $opt,
            $optval_ptr,
            $optval_len_ptr
        )
    );

    $optval = $self->_unpack($opt_type, $optval, $optval_ptr, $optval_len);
    return $optval;
}

sub set {
    my ($self, $opt, $opt_type, $opt_val) = @_;

    my $ffi = $self->_ffi;

    if ($opt_type eq 'binary') {
        $self->check_error(
            'zmq_setsockopt',
            $ffi->{str_zmq_setsockopt}->(
                $self->_socket,
                $opt,
                $opt_val,
                length($opt_val)
            )
        );
    }
    else {
        my $packed = $self->_pack($opt_type, $opt_val);

        my $opt_ptr   = unpack('L!', pack('P', $packed));
        my $opt_len   = length($packed);

        $self->check_error(
            'zmq_setsockopt',
            $ffi->{int_zmq_setsockopt}->(
                $self->_socket,
                $opt,
                $opt_ptr,
                $opt_len
            )
        );
    }
}

sub _pack {
    my ($self, $opt_type, $val) = @_;

    my $packed;
    for ($opt_type) {
        when (/^int64_t$/)  { $packed = int64_to_native($val)  }
        when (/^uint64_t$/) { $packed = uint64_to_native($val) }

        default {
            $packed = pack $self->_pack_type($opt_type), $val;
        }
    }

    return $packed;
}

sub _unpack {
    my ($self, $opt_type, $optval, $optval_ptr, $optval_len) = @_;

    for ($opt_type) {
        when (/^binary$/) {
            $optval_len = unpack 'L!', $optval_len;

            if ($optval_len == 0) {
                return;
            }

            $optval = $optval_ptr->tostr($optval_len);
        }

        when (/^int64_t$/)  { $optval = native_to_int64($optval)   }
        when (/^uint64_t$/) { $optval = native_to_uint64($optval)  }

        default {
            $optval = unpack $self->_pack_type($opt_type), $optval;
        }
    }

    return $optval;
}

sub _pack_type {
    my ($self, $zmqtype) = @_;

    # these are the only opts we use native perl packing for
    for ($zmqtype) {
        when (/^int$/)      { return 'i!' }
        when (/^binary$/)   { return 'L!' }

        default { confess "unsupported type '$self->_ffi->{zmqtype}'" }
    }
}

sub close {
    my $self = shift;

    $self->check_error(
        'zmq_close',
        $self->_ffi->{zmq_close}->($self->_socket)
    );

    $self->_socket(-1);
}

sub _init_ffi {
    my $self = shift;

    my $soname = $self->soname;

    my $ffi = {};
    $ffi->{zmq_socket} = FFI::Raw->new(
        $soname => 'zmq_socket',
        FFI::Raw::ptr, # returns socket ptr
        FFI::Raw::ptr, # takes ctx ptr
        FFI::Raw::int  # socket type
    );

    $ffi->{zmq_getsockopt} = FFI::Raw->new(
        $soname => 'zmq_getsockopt',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # socket ptr,
        FFI::Raw::int, # option constant
        FFI::Raw::ptr, # buf for option value
        FFI::Raw::ptr  # buf for size of option value
    );

    $ffi->{int_zmq_setsockopt} = FFI::Raw->new(
        $soname => 'zmq_setsockopt',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # socket ptr,
        FFI::Raw::int, # option constant
        FFI::Raw::ptr, # ptr to value int
        FFI::Raw::int  # size of option value
    );

    $ffi->{str_zmq_setsockopt} = FFI::Raw->new(
        $soname => 'zmq_setsockopt',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # socket ptr,
        FFI::Raw::int, # option constant
        FFI::Raw::str, # ptr to value string
        FFI::Raw::int  # size of option value
    );

    $ffi->{zmq_connect} = FFI::Raw->new(
        $soname => 'zmq_connect',
        FFI::Raw::int,
        FFI::Raw::ptr,
        FFI::Raw::str
    );

    $ffi->{zmq_bind} = FFI::Raw->new(
        $soname => 'zmq_bind',
        FFI::Raw::int,
        FFI::Raw::ptr,
        FFI::Raw::str
    );

    $ffi->{zmq_msg_init} = FFI::Raw->new(
        $soname => 'zmq_msg_init',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # zmq_msg_t ptr
    );

    $ffi->{zmq_msg_init_size} = FFI::Raw->new(
        $soname => 'zmq_msg_init_size',
        FFI::Raw::int,
        FFI::Raw::ptr,
        FFI::Raw::int
    );

    $ffi->{zmq_msg_size} = FFI::Raw->new(
        $soname => 'zmq_msg_size',
        FFI::Raw::int, # returns msg size in bytes
        FFI::Raw::ptr  # msg ptr
    );

    $ffi->{zmq_msg_data} = FFI::Raw->new(
        $soname => 'zmq_msg_data',
        FFI::Raw::ptr, # msg data ptr
        FFI::Raw::ptr  # msg ptr
    );

    $ffi->{zmq_msg_close} = FFI::Raw->new(
        $soname => 'zmq_msg_data',
        FFI::Raw::int, # retval
        FFI::Raw::ptr  # msg ptr
    );

    $ffi->{zmq_close} = FFI::Raw->new(
        $soname => 'zmq_close',
        FFI::Raw::int,
        FFI::Raw::ptr,
    );

    $ffi->{memcpy} = FFI::Raw->new(
        undef, 'memcpy',
        FFI::Raw::ptr,  # dest filled
        FFI::Raw::ptr,  # dest buf
        FFI::Raw::ptr,  # src
        FFI::Raw::int   # buf size
    );

    return $ffi;
}

sub DEMOLISH {
    my $self = shift;

    unless ($self->_socket == -1) {
        $self->close();
    }
}

__PACKAGE__->meta->make_immutable();
