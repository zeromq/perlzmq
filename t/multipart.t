use strict;
use warnings;

use Test::More;
use Test::Warnings;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_DEALER ZMQ_ROUTER ZMQ_DONTWAIT ZMQ_SNDMORE);

use Scalar::Util qw(blessed);
use Sub::Override;

my $endpoint = "ipc://test-zmq-ffi-$$";
my $ctx      = ZMQ::FFI->new();

my $d = $ctx->socket(ZMQ_DEALER);
$d->set_identity('mydealer');

my $r = $ctx->socket(ZMQ_ROUTER);

$d->connect($endpoint);
$r->bind($endpoint);


subtest 'multipart send/recv',
sub {
    $d->send_multipart([qw(ABC DEF GHI)]);

    my @recvd = $r->recv_multipart;
    is_deeply
        \@recvd,
        [qw(mydealer ABC DEF GHI)],
        'got dealer ident and message';
};


subtest 'multipart flags',
sub {
    my $sock_class = blessed($d);

    my @expected_flags = (
        ZMQ_SNDMORE | ZMQ_DONTWAIT,
        ZMQ_SNDMORE | ZMQ_DONTWAIT,
        ZMQ_DONTWAIT,
    );

    my @expected_flags_strs = (
        'ZMQ_SNDMORE | ZMQ_DONTWAIT',
        'ZMQ_SNDMORE | ZMQ_DONTWAIT',
        'ZMQ_DONTWAIT',
    );

    my $verify_flags = sub {
        my ($self, $msg, $flags) = @_;

        ok  $flags == (shift @expected_flags),
            q($flags == ).(shift @expected_flags_strs);
    };

    my $ov = Sub::Override->new(
        "${sock_class}::send",
        $verify_flags
    );

    $d->send_multipart([qw(ABC DEF GHI)], ZMQ_DONTWAIT);
};


done_testing;
