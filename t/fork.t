use strict;
use warnings;

use Test::More;

use ZMQ::FFI;
use ZMQ::Constants qw(ZMQ_REQ);

my $c = ZMQ::FFI->new();
my $s = $c->socket(ZMQ_REQ);
$s->connect("ipc://tmp/zmq-ffi-$$");

my $child_pid = open(FROM_CHILDTEST, '-|') // die "fork failed $!";

if ($child_pid) {
    # parent process, do test assertions here

    my $result;
    read(FROM_CHILDTEST, $result, 128);

    waitpid $child_pid, 0;

    is $result, 'ok', 'child process ignored zmq cleanup';
}
else {
    # check test expectataions,
    # and print 'ok' or 'not ok' depending on result

    no warnings qw/redefine once/;

    my $s_closed;
    my $c_destroyed;

    my ($major) = $c->version;
    if ($major == 2) {
        *ZMQ::FFI::ZMQ2::Socket::zmq_close = sub { $s_closed = 1; };
        *ZMQ::FFI::ZMQ2::Context::zmq_term = sub { $c_destroyed = 1; };
    }
    else {
        *ZMQ::FFI::ZMQ3::Socket::zmq_close = sub { $s_closed = 1; };
        *ZMQ::FFI::ZMQ3::Context::zmq_ctx_destroy = sub { $c_destroyed = 1; };
    }


    # explicitly undef ctx/socket cloned from parent to trigger DEMOLISH/
    # cleanup logic.. then verify that close/destroy was not, in fact, called
    # when instance pids don't match current process pid

    my $fail = 0;

    if ( $c->_pid == $$ ) { print "context pid shouldn't match child"; exit; }
    if ( $s->_pid == $$ ) { print "socket pid shouldn't match child"; exit; }

    undef $s;
    undef $c;

    if ( $s_closed ) { print "parent socket closed in child!"; exit; }
    if ( $c_destroyed) { print "parent context destroyed in child!"; exit; }

    print 'ok';
    exit;
}

done_testing;
