use strict;
use warnings;

use Test::More;
use Test::Warnings;

use AnyEvent;
use ZMQ::FFI qw(ZMQ_PUSH ZMQ_PULL);

my $endpoint = "inproc://test-zmq-ffi-$$";
my @expected = qw(foo bar baz);
my $ctx      = ZMQ::FFI->new();

my $pull = $ctx->socket(ZMQ_PULL);
$pull->bind($endpoint);

my $fd = $pull->get_fd();

my $cv = AE::cv;

my $recv = 0;
my $w = AE::io $fd, 0, sub {
    while ($pull->has_pollin) {
        my $msg = $pull->recv();
        is $msg, $expected[$recv], "got message $recv";

        $recv++;
        if ($recv == 3) {
            $cv->send;
        }
    }
};


my $push = $ctx->socket(ZMQ_PUSH);
$push->connect($endpoint);

my $t;
my $sent = 0;
$t = AE::timer 0, .1, sub {
    $push->send($expected[$sent]);

    $sent++;
    if ($sent == 3) {
        undef $t;
    }
};

$cv->recv;

done_testing;
