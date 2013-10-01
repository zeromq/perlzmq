package ZMQ::FFI::Util;

use strict;
use warnings;

use FFI::Raw;
use Carp;

use Sub::Exporter -setup => {
    exports => [qw(
        zcheck_error
        zcheck_null
    )],
};

my $zmq_errno = FFI::Raw->new(
    'libzmq.so',
    'zmq_errno',
    FFI::Raw::int
);

my $zmq_strerror = FFI::Raw->new(
    'libzmq.so',
    'zmq_strerror',
    FFI::Raw::str,
    FFI::Raw::int
);

sub zcheck_error {
    my ($func, $rc) = @_;

    if ( $rc == -1 ) {
        zdie($func);
    }
}

sub zcheck_null {
    my ($func, $obj) = @_;

    unless ($obj) {
        zdie($func);
    }
}

sub zdie {
    my ($func) = @_;

    croak "$func: ".$zmq_strerror->($zmq_errno->());
}

1;
