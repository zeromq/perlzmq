use strict;
use warnings;

use Test::More;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_DEALER ZMQ_ROUTER ZMQ_DONTWAIT ZMQ_SNDMORE);

my $endpoint = "ipc:///tmp/test-zmq-ffi-$$";
my $ctx      = ZMQ::FFI->new();

my $d = $ctx->socket(ZMQ_DEALER);
$d->set_identity('mydealer');

my $r = $ctx->socket(ZMQ_ROUTER);

$d->connect($endpoint);
$r->bind($endpoint);

$d->send_multipart([qw(ABC DEF GHI)], ZMQ_DONTWAIT);

my @recvd = $r->recv_multipart;
is_deeply
    \@recvd,
    [qw(mydealer ABC DEF GHI)],
    'got dealer ident and message';

done_testing;
