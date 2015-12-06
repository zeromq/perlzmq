use strict;
use warnings;

use Test::More;
use Test::Warnings;
use Math::BigInt;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(:all);
use ZMQ::FFI::Util qw(zmq_version);

subtest 'ctx version',
sub {
    my $ctx = ZMQ::FFI->new();

    is_deeply
        [zmq_version()],
        [$ctx->version()],
        'util version and ctx version match';
};

subtest 'ctx options',
sub {

    plan skip_all =>
        "libzmq 2.x found, don't test 3.x style ctx options"
        if (zmq_version())[0] == 2;

    my $ctx = ZMQ::FFI->new( threads => 42, max_sockets => 42 );

    is $ctx->get(ZMQ_IO_THREADS),  42, 'threads set to 42';
    is $ctx->get(ZMQ_MAX_SOCKETS), 42, 'max sockets set to 42';

    $ctx->set(ZMQ_IO_THREADS, 1);
    $ctx->set(ZMQ_MAX_SOCKETS, 1024);

    is $ctx->get(ZMQ_IO_THREADS),     1, 'threads set to 1';
    is $ctx->get(ZMQ_MAX_SOCKETS), 1024, 'max sockets set to 1024';
};

subtest 'convenience options',
sub {
    my $ctx = ZMQ::FFI->new();
    my $s   = $ctx->socket(ZMQ_DEALER);

    is $s->get_linger(), 0, 'got default linger';

    $s->set_linger(42);
    is $s->get_linger(), 42, 'set linger';

    is $s->get_identity(), undef, 'got default identity';

    $s->set_identity('foo');
    is $s->get_identity(), 'foo', 'set identity';
};

subtest 'string options',
sub {
    my ($major) = zmq_version;
    plan skip_all =>
        "no string options exist for libzmq 2.x"
        if $major == 2;

    my $ctx = ZMQ::FFI->new();
    my $s   = $ctx->socket(ZMQ_DEALER);

    my $endpoint = "ipc://test-zmq-ffi-$$";
    $s->bind($endpoint);

    is $s->get(ZMQ_LAST_ENDPOINT, 'string'), $endpoint, 'got last endpoint';

    if ($major >= 4) {
        $s->set(ZMQ_PLAIN_USERNAME, 'string', 'foo');
        is $s->get(ZMQ_PLAIN_USERNAME, 'string'), 'foo',
            'setting/getting zmq4 string opt works'
    }
};

subtest 'binary options',
sub {
    my $ctx = ZMQ::FFI->new();
    my $s   = $ctx->socket(ZMQ_DEALER);

    # 255 characters long
    my $long_ident = 'ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo';

    $s->set(ZMQ_IDENTITY, 'binary', $long_ident);
    is $s->get(ZMQ_IDENTITY, 'binary'), $long_ident, 'set long identity';
};

subtest 'uint64_t options',
sub {
    my $max_uint64 = Math::BigInt->new('18446744073709551615');
    my $ctx        = ZMQ::FFI->new();

    my $s = $ctx->socket(ZMQ_REQ);

    $s->set(ZMQ_AFFINITY, 'uint64_t', $max_uint64);
    is $s->get(ZMQ_AFFINITY, 'uint64_t'), $max_uint64->bstr(),
        'set/got max unsigned 64 bit int option value';
};

subtest 'int64_t options',
sub {
    # max negative 64bit values don't currently make
    # sense with any zmq opts, so we'll stick with positive
    my $max_int64 = Math::BigInt->new('9223372036854775807');
    my $ctx       = ZMQ::FFI->new();

    my ($major) = $ctx->version;

    # no int64 opts exist in both versions
    my $opt;
    if ($major == 2) {
        $opt = ZMQ_SWAP;
    }
    elsif ($major == 3 || $major == 4) {
        $opt = ZMQ_MAXMSGSIZE;
    }
    else {
        die "Unsupported zmq version $major";
    }

    my $s = $ctx->socket(ZMQ_REQ);

    $s->set($opt, 'int64_t', $max_int64);
    is $s->get($opt, 'int64_t'), $max_int64->bstr(),
        'set/got max signed 64 bit int option value';
};

done_testing;
