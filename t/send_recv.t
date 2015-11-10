use strict;
use warnings;
use Test::More;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ ZMQ_REP);

my $endpoint = "ipc://test-zmq-ffi-$$";
my $ctx      = ZMQ::FFI->new( threads => 1 );

my $s1 = $ctx->socket(ZMQ_REQ);
$s1->connect($endpoint);

my $s2 = $ctx->socket(ZMQ_REP);
$s2->bind($endpoint);

$s1->send('ohhai');

is
    $s2->recv(),
    'ohhai',
    'received message';

$s1->close();
is $s1->socket_ptr, -1, 's1 socket ptr set to -1 after explicit close';

$s2->close();
is $s2->socket_ptr, -1, 's2 socket ptr set to -1 after explicit close';

$ctx->destroy();
is $ctx->context_ptr, -1, 'ctx ptr set to -1 after explicit destroy';

done_testing;
