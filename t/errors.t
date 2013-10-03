use strict;
use warnings;

use Test::More;
use Test::Exception;

use FFI::Raw;
use Errno qw(EINVAL);

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ);


my $ctx = ZMQ::FFI->new();

throws_ok { $ctx->socket(-1) } qr/invalid argument/i,
    q(invalid socket type dies with EINVAL);


my $socket = $ctx->socket(ZMQ_REQ);

throws_ok { $socket->connect('foo') } qr/invalid argument/i,
    q(invalid endpoint dies with EINVAL);

$socket->close();

done_testing;
