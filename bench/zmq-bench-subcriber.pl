use v5.10;
use strict;
use warnings;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_SUB);

my $ctx = ZMQ::FFI->new();
my $s = $ctx->socket(ZMQ_SUB);
$s->connect('ipc:///tmp/zmq-bench-c');
$s->connect('ipc:///tmp/zmq-bench-xs');
$s->connect('ipc:///tmp/zmq-bench-ffi');
$s->subscribe('');

my $rh = {c => 0, ffi => 0, xs => 0};
my $r;
while (1) {
    $r = $s->recv();

    $rh->{$r}++;

    if ( ($rh->{$r} % 1_000) == 0 ) {
        say $r."=".$rh->{$r};
    }
}
