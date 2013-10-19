use strict;
use warnings;

use Test::More;
use Test::Exception;

use FFI::Raw;
use Errno qw(EINVAL);

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ);

# get the EINVAL error string in a locale aware way
$! = EINVAL;
my $einval_str = "$!";

my $ctx = ZMQ::FFI->new();

throws_ok { $ctx->socket(-1) } qr/$einval_str/i,
    q(invalid socket type dies with EINVAL);


my $socket = $ctx->socket(ZMQ_REQ);

throws_ok { $socket->connect('foo') } qr/$einval_str/i,
    q(invalid endpoint dies with EINVAL);

done_testing;
