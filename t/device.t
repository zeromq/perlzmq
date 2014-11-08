use strict;
use warnings;

use Test::More;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_STREAMER ZMQ_PUSH ZMQ_PULL);

use Time::HiRes q(usleep);

my $server_address = "ipc:///tmp/test-zmq-ffi-$$-front";
my $worker_address = "ipc:///tmp/test-zmq-ffi-$$-back";

# Set up the streamer device in its own process
my $device = fork;
die "fork failed: $!" unless defined $device;

if ( $device == 0 ) {
    my $ctx = ZMQ::FFI->new();

    my $front = $ctx->socket(ZMQ_PULL);
    $front->bind($server_address);

    my $back  = $ctx->socket(ZMQ_PUSH);
    $back->bind($worker_address);

    $ctx->device(ZMQ_STREAMER, $front, $back);
    warn "device exited: $!";

    exit 0;
}

subtest 'device', sub {
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
};

# tear down the device
kill TERM => $device;
waitpid $device, 0;

done_testing;

