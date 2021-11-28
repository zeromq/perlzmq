use strict;
use warnings;

use Test::More;
use Test::Warnings;
use lib 't/lib';
use ZMQTest;

use ZMQ::FFI qw(ZMQ_PUSH ZMQ_PULL);

use Time::HiRes q(usleep);
use POSIX ":sys_wait_h";

if( ! ZMQTest->platform_can_fork ) {
    plan skip_all => 'fork(2) unavailable';
}

my $server_address = "ipc:///tmp/test-zmq-ffi-$$-front";
my $worker_address = "ipc:///tmp/test-zmq-ffi-$$-back";

# Set up the proxy in its own process
my $proxy = fork;
die "fork failed: $!" unless defined $proxy;

if ( $proxy == 0 ) {
    my $ctx = ZMQ::FFI->new();

    my $front = $ctx->socket(ZMQ_PULL);
    $front->bind($server_address);

    my $back  = $ctx->socket(ZMQ_PUSH);
    $back->bind($worker_address);

    $ctx->proxy($front, $back);
    warn "proxy exited: $!";

    exit 0;
}

subtest 'proxy', sub {
    my $ctx = ZMQ::FFI->new();

    my $server = $ctx->socket(ZMQ_PUSH);
    $server->connect($server_address);

    my $worker = $ctx->socket(ZMQ_PULL);
    $worker->connect($worker_address);

    my $message = 'ohhai';
    $server->send($message);

    until ($worker->has_pollin) {

        # sleep for a 100ms to compensate for slow subscriber problem
        usleep 100_000;
    }

    my $payload = $worker->recv;
    is $payload, $message, "Message received";

    kill TERM => $proxy;
    waitpid($proxy,0);
};


done_testing;

