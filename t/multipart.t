use strict;
use warnings;

use Test::More;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_DEALER ZMQ_ROUTER ZMQ_DONTWAIT ZMQ_SNDMORE);

my $endpoint = "ipc:///tmp/test-zmq-ffi-$$";
my $ctx      = ZMQ::FFI->new();

ok $ctx;

my $d = $ctx->socket(ZMQ_DEALER);

isa_ok($d, "ZMQ::FFI::SocketBase");

$d->set_identity('mydealer');

diag "Identity set";

my $r = $ctx->socket(ZMQ_ROUTER);

isa_ok($d, "ZMQ::FFI::SocketBase");

diag "Connecting ...";
$d->connect($endpoint);
diag "Binding ...";
$r->bind($endpoint);

diag "Sending ...";
$d->send_multipart([qw(ABC DEF GHI)], ZMQ_DONTWAIT);

diag "Receiving ...";
my @recvd = $r->recv_multipart;
is_deeply
    \@recvd,
    [qw(mydealer ABC DEF GHI)],
    'got dealer ident and message';

done_testing;
