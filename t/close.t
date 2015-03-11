use strict;
use warnings;

use Test::More;
use Sys::SigAction qw(timeout_call);

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ);

subtest 'close with unsent messages', sub {
    my $timed_out = timeout_call 3, sub {
        my $ctx = ZMQ::FFI->new();
        my $s   = $ctx->socket(ZMQ_REQ);

        $s->connect("ipc:///tmp/test-zmq-ffi-$$");
        $s->send('ohhai');
    };

    ok !$timed_out,
       'implicit Socket close done correctly (ctx destruction does not hang)';
};

done_testing;
