use strict;
use warnings;

use Test::More;
use Test::Warnings;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_PUSH ZMQ_PULL);

use Time::HiRes q(usleep);
use POSIX ":sys_wait_h";

my $server_address = "ipc://test-zmq-ffi-$$-front";
my $worker_address = "ipc://test-zmq-ffi-$$-back";

# Set up the proxy in its own process
my $proxy = fork;
die "fork failed: $!" unless defined $proxy;

if ( $proxy == 0 ) {
    # make sure child shuts down cleanly
    $SIG{TERM} = sub { exit 0 };

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
};

# tear down the proxy
do {
    # XXX
    # Occasionally the TERM signal handler does not actually fire, even
    # though kill returns 1 (indicating the child was successfully signaled).
    # As a result waitpid blocks, hanging the test.
    #
    # As a workaround until the problem is understood, check waitpid in a loop
    # and kill until the process actually exits

    kill TERM => $proxy;
} while (waitpid($proxy, WNOHANG) > 0);

done_testing;

