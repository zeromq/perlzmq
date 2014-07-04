use strict;
use warnings;

use Test::More;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_PUB ZMQ_SUB ZMQ_DONTWAIT);

use Time::HiRes q(usleep);

subtest 'pubsub',
sub {
    my $endpoint = "ipc:///tmp/test-zmq-ffi-$$";

    my $ctx = ZMQ::FFI->new();

    my $s = $ctx->socket(ZMQ_SUB);
    my $p = $ctx->socket(ZMQ_PUB);

    $s->connect($endpoint);
    $p->bind($endpoint);

    {
        $s->subscribe('');
        $p->send('ohhai');

        until ($s->has_pollin) {
            # sleep for a 100ms to compensate for slow subscriber problem
            usleep 100_000;
            $p->send('ohhai');
        }

        my $msg = $s->recv();
        is $msg, 'ohhai', 'got msg sent to all topics';

        $s->unsubscribe('');
    }

    {
        $s->subscribe('mytopic');
        $p->send('mytopic ohhai');

        until ($s->has_pollin) {
            usleep 100_000;
            $p->send('mytopic ohhai');
        }

        my $msg = $s->recv();
        is $msg, 'mytopic ohhai', 'got msg sent to mytopic';
    }
};

done_testing;

