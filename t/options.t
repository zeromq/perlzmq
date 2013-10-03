use strict;
use warnings;
use Test::More;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(:all);
use ZMQ::FFI::Util qw(zmq_version);

my ($major) = zmq_version();

subtest 'ctx options',
sub {
    if ($major == 2) {
        plan skip_all =>
            "libzmq 2.x found, don't test 3.x style ctx options";
    }

    my $ctx = ZMQ::FFI->new( threads => 42, max_sockets => 42 );

    is
        join('.', zmq_version()),
        $ctx->version(),
        'util version and ctx version match';

    is $ctx->get(ZMQ_IO_THREADS),  42, 'threads set to 42';
    is $ctx->get(ZMQ_MAX_SOCKETS), 42, 'max sockets set to 42';

    $ctx->set(ZMQ_IO_THREADS, 1);
    $ctx->set(ZMQ_MAX_SOCKETS, 1024);

    is $ctx->get(ZMQ_IO_THREADS),     1, 'threads set to 1';
    is $ctx->get(ZMQ_MAX_SOCKETS), 1024, 'max sockets set to 1024';
};

subtest 'socket options',
sub {
    my $ctx = ZMQ::FFI->new();

    my $s = $ctx->socket(ZMQ_REQ);

    is $s->get_linger(), -1, 'got default linger';
    $s->set_linger(42);
    is $s->get_linger(), 42, 'set linger';

    is $s->get_identity(), undef, 'got default identity';
    $s->set_identity('foo');
    is $s->get_identity(), 'foo', 'set identity';
};

done_testing;
