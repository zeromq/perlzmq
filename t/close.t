use strict;
use warnings;

use Test::More;
use Test::Warnings;
use lib 't/lib';
use ZMQTest;

if( ZMQTest->platform_can_sigaction ) {
    require Sys::SigAction;
    Sys::SigAction->import(qw(timeout_call));
} else {
    plan skip_all => 'No Sys::SigAction';
}

use ZMQ::FFI qw(ZMQ_REQ);

subtest 'close with unsent messages', sub {
    my $timed_out = timeout_call(5, sub {
        my $ctx = ZMQ::FFI->new();
        my $s   = $ctx->socket(ZMQ_REQ);

        $s->connect("ipc:///tmp/test-zmq-ffi-$$");
        $s->send('ohhai');
    });

    ok !$timed_out,
       'implicit Socket close done correctly (ctx destruction does not hang)';
};

done_testing;
