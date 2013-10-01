package ZMQ::FFI::Util;

use strict;
use warnings;

use FFI::Raw;
use Carp;

use Sub::Exporter -setup => {
    exports => [qw(
        check_zerror
        check_znull
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


sub check_zerror {
    my ($func, $rc) = @_;
    
    if ( $rc == -1 ) { 
        zdie($func);
    }
}

sub check_znull {
    my ($func, $obj) = @_;

    unless ($obj) {
        zdie($func);
    }
}

sub zdie {
    my ($func) = @_;

    confess "$func: ".$zmq_strerror->($zmq_errno->());
}

1;
