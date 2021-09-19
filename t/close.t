use strict;
use warnings;

use Test::More;
use Test::Warnings;

if ( $^O eq 'MSWin32' ) {
    plan skip_all => 'Skipping on MSWin32, no Sys::SigAction';
} else {
    require Sys::SigAction;
    Sys::SigAction->import(qw(timeout_call));
}

use ZMQ::FFI qw(ZMQ_REQ);

subtest 'close with unsent messages', sub {
    my $timed_out = timeout_call(5, sub {
        my $ctx = ZMQ::FFI->new();
        my $s   = $ctx->socket(ZMQ_REQ);

        $s->connect("inproc://test-zmq-ffi-$$");
        $s->send('ohhai');
    });

    ok !$timed_out,
       'implicit Socket close done correctly (ctx destruction does not hang)';
};

done_testing;
