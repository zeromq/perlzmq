use strict;
use warnings;

use Test::More;
use Test::Warnings;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_ROUTER ZMQ_REQ);

use Time::HiRes q(usleep);

subtest 'router-req', sub {
    my $endpoint = "ipc://test-zmq-ffi-$$";

    my $ctx = ZMQ::FFI->new();

    my $req = $ctx->socket(ZMQ_REQ);
    my $rtr = $ctx->socket(ZMQ_ROUTER);

    $req->connect($endpoint);
    $rtr->bind($endpoint);

    my $message = 'ohhai';

    {
        $req->send($message);

        until ($rtr->has_pollin) {

            # sleep for a 100ms to compensate for slow subscriber problem
            usleep 100_000;
        }

        my ($identifier, $null, $payload) = $rtr->recv_multipart();
        is $null,    '',       "Null is really null";
        is $payload, $message, "Message received";

        $rtr->send_multipart([$identifier, '', '' . reverse($payload)]);

        until ($req->has_pollin) {
            usleep 100_000;
        }

        my @result = $req->recv();
        is reverse($result[0]), $message, "Message received by client";
    }
};

done_testing;

