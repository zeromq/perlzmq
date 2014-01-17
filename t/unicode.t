use strict;
use warnings;

use Test::More;
use utf8;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ ZMQ_REP ZMQ_DONTWAIT);

my $endpoint = "ipc:///tmp/test-zmq-ffi-$$";

my $ctx = ZMQ::FFI->new();

my $q = $ctx->socket(ZMQ_REQ);
my $p = $ctx->socket(ZMQ_REP);

$q->connect($endpoint);
$p->bind($endpoint);

my $pack_template = 'u*';

my $msg = 'werde ich von Dir hören?';
ok( utf8::is_utf8($msg), "This is a unicode message" );

subtest 'send_bytes' => sub {
    $q->send( $msg, ZMQ_DONTWAIT );

    my $delivered = $p->recv();

    {
        use bytes;
        is( length($delivered), length($msg), "Same number of bytes" );
        is( unpack( $pack_template, $delivered ),
            unpack( $pack_template, $msg ),
            "Byte identical"
        );
    }

    $p->send('thx');
    $q->recv();
};

subtest 'send_multipart_bytes' => sub {
    my $multipart = [ ($msg) x 3 ];

    $q->send_multipart( $multipart, ZMQ_DONTWAIT );

    my @delivered = $p->recv_multipart();

    is_deeply(
        [ map { unpack( $pack_template, $_ ) } @delivered ],
        [ map { unpack( $pack_template, $_ ) } @$multipart ],

        "Oh yes, we're all just bytes"
    );

    $p->send('thx');
    $q->recv();
};

subtest 'recv_string' => sub {
    $q->send( $msg, ZMQ_DONTWAIT );

    my $delivered = $p->recv_string();
    is( $delivered, $msg, "The strings are unicode and identical" );

    $p->send('thx');
    $q->recv();

};

subtest 'recv_multipart_string' => sub {
    my $multipart = [ ($msg) x 3 ];
    $q->send_multipart( $multipart, ZMQ_DONTWAIT );

    my @delivered = $p->recv_multipart_string();
    is_deeply( \@delivered, $multipart, "Many unicode strings" );

    $p->send('thx');
    $q->recv();

};

{
    # cleanup

    foreach ( $q, $p ) {
        $_->close();
    }

    $ctx->destroy();
}

done_testing();
