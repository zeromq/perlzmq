use strict;
use warnings;

use utf8;
use Test::More;
use List::Util qw(sum);

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_PUSH ZMQ_PULL);

my $endpoint = "ipc:///tmp/test-zmq-ffi-$$";
my $ctx      = ZMQ::FFI->new();

my $s1 = $ctx->socket(ZMQ_PUSH);
$s1->connect($endpoint);

my $s2 = $ctx->socket(ZMQ_PULL);
$s2->bind($endpoint);

my $pack_template = 'U*';
my $msg = 'werde ich von Dir hören?';

subtest 'send_unicode_bytes' => sub {
    ok utf8::is_utf8($msg), "created unicode message";
    $s1->send($msg);

    my $recvd = $s2->recv();

    {
        use bytes;

        is length($recvd), length($msg), "byte length matches";

        my @sent_bytes  = unpack($pack_template, $msg);
        my @recvd_bytes = unpack($pack_template, $recvd);

        is_deeply
            \@recvd_bytes,
            \@sent_bytes,
            "bytes match"
        ;
    }
};

subtest 'send_multipart_unicode_bytes' => sub {
    my $multipart = [ ($msg) x 3 ];

    my $is_unicode = 1;
    $is_unicode &&= utf8::is_utf8($_) for (@$multipart);

    ok $is_unicode, "created unicode message parts";

    $s1->send_multipart($multipart);

    my @recvd = $s2->recv_multipart();

    {
        use bytes;

        my $sent_len  = sum(map { length($_) } @$multipart);
        my $recvd_len = sum(map { length($_) } @recvd);

        is $recvd_len, $sent_len, "byte length matches";

        my @sent_bytes  = map { unpack( $pack_template, $_ ) } @$multipart;
        my @recvd_bytes = map { unpack( $pack_template, $_ ) } @recvd;

        is_deeply
            \@recvd_bytes,
            \@sent_bytes,
            "bytes match"
        ;
    }
};

done_testing();
