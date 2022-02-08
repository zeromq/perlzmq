use strict;
use warnings;

use Test::More;
use Test::Warnings;
use Test::Exception;
use lib 't/lib';
use ZMQTest;

use ZMQ::FFI qw(ZMQ_STREAMER ZMQ_PUSH ZMQ_PULL);
use ZMQ::FFI::Util qw(zmq_version);

use Time::HiRes q(usleep);
use POSIX ":sys_wait_h";

if( ! ZMQTest->platform_can_fork ) {
    plan skip_all => 'fork(2) unavailable';
}

my $server_address = "ipc:///tmp/test-zmq-ffi-$$-front";
my $worker_address = "ipc:///tmp/test-zmq-ffi-$$-back";

my $device;

sub mkdevice {
    my $ctx = ZMQ::FFI->new();

    my $front = $ctx->socket(ZMQ_PULL);
    $front->bind($server_address);

    my $back  = $ctx->socket(ZMQ_PUSH);
    $back->bind($worker_address);

    $ctx->device(ZMQ_STREAMER, $front, $back);
    warn "device exited: $!";

    exit 0;
}

my ($major) = zmq_version();
if ($major > 2) {
    throws_ok { mkdevice() }
        qr/zmq_device not available in zmq >= 3\.x/,
        'zmq_device version error for zmq >= 3.x';
}
else {
    # Set up the streamer device in its own process
    $device = fork;
    die "fork failed: $!" unless defined $device;

    if ( $device == 0 ) {
        mkdevice();
    }
}

subtest 'device', sub {
    my $ctx = ZMQ::FFI->new();

    if ($major > 2) {
        plan skip_all => 'zmq_device not available in zmq >= 3.x';
    }

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

    kill TERM => $device;
    waitpid($device,0);
};


done_testing;

