use strict;
use warnings;
use v5.10;

use FFI::Platypus::Declare;
use ZMQ::LibZMQ3;

use ZMQ::FFI::Constants qw(:all);

use Benchmark qw(:all);

lib 'libzmq.so';

attach(
    ['zmq_ctx_new' => 'zmqffi_ctx_new']
        => [] => 'pointer'
);

attach(
    ['zmq_socket' => 'zmqffi_socket']
        => ['pointer', 'int'] => 'pointer'
);

attach(
    ['zmq_bind' => 'zmqffi_bind']
        => ['pointer', 'string'] => 'int'
);

attach(
    ['zmq_send' => 'zmqffi_send']
        => ['pointer', 'string', 'size_t', 'int'] => 'int'
);

attach(
    ['zmq_version' => 'zmqffi_version']
        => ['int*', 'int*', 'int*'] => 'void'
);

my $ffi_ctx = zmqffi_ctx_new();
die 'ffi ctx error' unless $ffi_ctx;

my $ffi_socket = zmqffi_socket($ffi_ctx, ZMQ_PUB);
die 'ffi socket error' unless $ffi_socket;

my $rv;

$rv = zmqffi_bind($ffi_socket, "ipc:///tmp/zmq-bench-ffi");
die 'ffi bind error' if $rv == -1;

my $xs_ctx = zmq_ctx_new();
die 'xs ctx error' unless $xs_ctx;

my $xs_socket = zmq_socket($xs_ctx, ZMQ_PUB);
die 'xs socket error' unless $xs_socket;

$rv = zmq_bind($xs_socket, "ipc:///tmp/zmq-bench-xs");
die 'xs bind error' if $rv == -1;


my ($major, $minor, $patch);
zmqffi_version(\$major, \$minor, \$patch);

say "FFI ZMQ Version: " . join(".", $major, $minor, $patch);
say "XS  ZMQ Version: " . join(".", ZMQ::LibZMQ3::zmq_version());

# for (1..10_000_000) {
#     # die 'xs send error ' if -1 == zmq_send($xs_socket, 'xs', 2, 0);
#     die 'ffi send error' if -1 == zmqffi_send($ffi_socket, 'ffi', 3, 0);
# }

my $r = timethese 1_000_000, {
    'XS'  => sub {
        die 'xs send error ' if -1 == zmq_send($xs_socket, 'xs', 2, 0);
    },

    'FFI' => sub {
        die 'ffi send error' if -1 == zmqffi_send($ffi_socket, 'ffi', 3, 0);
    },
};

cmpthese($r);
