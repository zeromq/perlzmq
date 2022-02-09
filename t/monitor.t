use strict;
use warnings;

use v5.10;

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

use ZMQ::FFI qw(
    ZMQ_DEALER ZMQ_PAIR

    ZMQ_EVENT_ALL
    ZMQ_EVENT_CONNECTED
    ZMQ_EVENT_CONNECT_DELAYED
    ZMQ_EVENT_CONNECT_RETRIED
    ZMQ_EVENT_LISTENING
    ZMQ_EVENT_BIND_FAILED
    ZMQ_EVENT_ACCEPTED
    ZMQ_EVENT_ACCEPT_FAILED
    ZMQ_EVENT_CLOSED
    ZMQ_EVENT_CLOSE_FAILED
    ZMQ_EVENT_DISCONNECTED
    ZMQ_EVENT_MONITOR_STOPPED
    ZMQ_EVENT_HANDSHAKE_SUCCEEDED
);

sub dump_event {
    my ($socket) = @_;

    my ($major, $minor, $patch) = $socket->version;

    say "----------------------------------------";

    for my $message ($socket->recv_multipart()) {
        my $msg_len = length($message);

        my $is_text = 1;

        CHECK_TEXT:
        for (my $i = 0; $i < $msg_len; $i++) {
            my $c = ord(substr($message, $i, 1));

            if ($c < 32 || $c > 126) {
                $is_text = 0;
                last CHECK_TEXT;
            }
        }

        printf "[%03d] ", $msg_len;

        if ($is_text) {
            say $message;
        }
        else {
            if ($major == 3) {
                say unpack('H*', $message);
                my ($event, $ptr, $fd) = unpack('i x4 p i x4', $message);
                say "$event / $ptr / $fd";
            }
            else {
                my ($event, $data) = unpack('S L', $message);
                say "$event / $data";
            }
        }
    }
}

subtest 'monitor', sub {
    my $timed_out = timeout_call(5, sub {
        my $ctx = ZMQ::FFI->new();

        my ($major, $minor, $patch) = $ctx->version();

        if ($major < 3) {
            pass('ZMQ2 does not support zmq_socket_monitor');
            return;
        }

        my $s = $ctx->socket(ZMQ_DEALER);
        my $c = $ctx->socket(ZMQ_DEALER);

        $s->monitor('inproc://monitor-server', ZMQ_EVENT_ALL);
        $c->monitor('inproc://monitor-client', ZMQ_EVENT_ALL);

        my $ms = $ctx->socket(ZMQ_PAIR);
        my $mc = $ctx->socket(ZMQ_PAIR);
        my $ts = $ctx->socket(ZMQ_PAIR);

        $ms->connect('inproc://monitor-server');
        $mc->connect('inproc://monitor-client');

        my $endpoint = ZMQTest->endpoint("test-zmq-ffi-$$");

        $s->bind($endpoint);

        my ($id, $value, $data) = $ms->recv_event();

        cmp_ok $id, '==', ZMQ_EVENT_LISTENING,
            'Received ZMQ_EVENT_LISTENING event from server socket';

        cmp_ok $data, 'eq', $endpoint,
            "Received endpoint is $endpoint";

        $c->connect($endpoint);

        ($id, $value, $data) = $ms->recv_event();

        cmp_ok $id, '==', ZMQ_EVENT_ACCEPTED,
            'Received ZMQ_EVENT_ACCEPTED event from server socket';

        cmp_ok $data, 'eq', $endpoint,
            "Received endpoint is $endpoint";

        ($id, $value, $data) = $mc->recv_event();

        cmp_ok $id, '==', ZMQ_EVENT_CONNECTED,
            'Received ZMQ_EVENT_CONNECTED event from client socket';

        cmp_ok $data, 'eq', $endpoint,
            "Received endpoint is $endpoint";

        $s->close();

        # WARNING:
        # ZMQ_EVENT_HANDSHAKE_SUCCEEDED event is happend from ZMQ 4.3.2
        # with unknown reason and this situation seems like a bug so we need
        # to change below test code after fixing this bug.
        if ($major >= 4 && $minor >= 3 && $patch >= 2)
        {
            ($id, $value, $data) = $ms->recv_event();

            cmp_ok $id, '==', ZMQ_EVENT_HANDSHAKE_SUCCEEDED
                'Received ZMQ_EVENT_HANDSHAKE_SUCCEEDED event from server socket';

            cmp_ok $data, 'eq', $endpoint,
                "Received endpoint is $endpoint";

            ($id, $value, $data) = $mc->recv_event();

            cmp_ok $id, '==', ZMQ_EVENT_HANDSHAKE_SUCCEEDED
                'Received ZMQ_EVENT_HANDSHAKE_SUCCEEDED event from client socket';

            cmp_ok $data, 'eq', $endpoint,
                "Received endpoint is $endpoint";
        }

        ($id, $value, $data) = $ms->recv_event();

        cmp_ok $id, '==', ZMQ_EVENT_CLOSED,
            'Received ZMQ_EVENT_CLOSED event from server socket';

        cmp_ok $data, 'eq', $endpoint,
            "Received endpoint is $endpoint";

        ($id, $value, $data) = $mc->recv_event();

        cmp_ok $id, '==', ZMQ_EVENT_DISCONNECTED,
            'Received ZMQ_EVENT_DISCONNECTED event from client socket';

        cmp_ok $data, 'eq', $endpoint,
            "Received endpoint is $endpoint";
    });

    ok !$timed_out,
       'implicit Socket close done correctly (ctx destruction does not hang)';
};

done_testing;
