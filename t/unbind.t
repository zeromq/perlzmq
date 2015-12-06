use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Exception;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ ZMQ_REP ZMQ_LAST_ENDPOINT);

my $e = "ipc://test-zmq-ffi-$$";

my $c = ZMQ::FFI->new();

my $s1 = $c->socket(ZMQ_REQ);
$s1->connect($e);

my $s2 = $c->socket(ZMQ_REP);
$s2->bind($e);

my ($major) = $c->version();

if ( $major == 2 ) {
    throws_ok { $s1->disconnect($e) }
                qr'not available in zmq 2.x',
                'threw unimplemented error for 2.x';

    throws_ok { $s2->unbind($e) }
                qr'not available in zmq 2.x',
                'threw unimplemented error for 2.x';
}
else {
    lives_ok { $s1->disconnect($e) } 'first disconnect lives';
    lives_ok { $s2->unbind($e)     } 'first unbind lives';

    dies_ok  { $s1->disconnect($e) } 'second disconnect dies';
    dies_ok  { $s2->unbind($e)     } 'second unbind dies';
}

done_testing;
