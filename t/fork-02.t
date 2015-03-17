use strict;
use warnings;

use Test::More;

use ZMQ::FFI;
use ZMQ::Constants qw(ZMQ_REQ);

#
# Test that we _do_ clean up contexts/sockets created in forked children
#

my $parent_c = ZMQ::FFI->new();
my $parent_s = $parent_c->socket(ZMQ_REQ);

my $child_pid  = open(FROM_CHILDTEST, '-|') // die "fork failed $!";

if ($child_pid) {
    # parent process, do test assertions here

    my $result;
    read(FROM_CHILDTEST, $result, 128);

    waitpid $child_pid, 0;

    is $result, 'ok',
        'child process did child ctx/socket cleanup';


    no warnings qw/redefine once/;

    my $parent_s_closed;
    my $parent_c_destroyed;

    my ($major) = $parent_c->version;
    if ($major == 2) {
        *ZMQ::FFI::ZMQ2::Socket::zmq_close = sub {
            $parent_s_closed = 1;
        };

        *ZMQ::FFI::ZMQ2::Context::zmq_term = sub {
            $parent_c_destroyed = 1;
        };
    }
    else {
        *ZMQ::FFI::ZMQ3::Socket::zmq_close = sub {
            $parent_s_closed = 1;
        };

        *ZMQ::FFI::ZMQ3::Context::zmq_ctx_destroy = sub {
            $parent_c_destroyed = 1;
        };
    }

    ok $parent_c->_pid == $$, "parent context pid _should_ match parent pid";
    ok $parent_s->_pid == $$, "parent socket pid _should_ match parent pid";

    # explicitly undef ctx/socket created in parent to trigger DEMOLISH/
    # cleanup logic.. then verify that close/destroy _was_ called
    # for ctx/socket created in parent

    undef $parent_s;
    undef $parent_c;

    ok $parent_s_closed, "parent socket closed in parent";
    ok $parent_c_destroyed, "parent context destroyed in parent";
}
else {
    # check test expectataions and print 'ok' if successful

    my $child_c = ZMQ::FFI->new();
    my $child_s = $child_c->socket(ZMQ_REQ);

    no warnings qw/redefine once/;

    my $child_s_closed;
    my $child_c_destroyed;

    my ($major) = $child_c->version;
    if ($major == 2) {
        *ZMQ::FFI::ZMQ2::Socket::zmq_close = sub {
            $child_s_closed = 1;
        };

        *ZMQ::FFI::ZMQ2::Context::zmq_term = sub {
            $child_c_destroyed = 1;
        };
    }
    else {
        *ZMQ::FFI::ZMQ3::Socket::zmq_close = sub {
            $child_s_closed = 1;
        };

        *ZMQ::FFI::ZMQ3::Context::zmq_ctx_destroy = sub {
            $child_c_destroyed = 1;
        };
    }

    if ( $child_c->_pid != $$ ) {
        print "child context pid _should_ match child pid"; exit;
    }

    if ( $child_s->_pid != $$ ) {
        print "child socket pid _should_ match child pid"; exit;
    }

    # explicitly undef ctx/socket created in child to trigger DEMOLISH/
    # cleanup logic.. then verify that close/destroy _was_ called
    # for ctx/socket created in child

    undef $child_s;
    undef $child_c;

    if ( !$child_s_closed )  {
        print "child socket not closed in child!"; exit;
    }

    if ( !$child_c_destroyed) {
        print "child context not destroyed in child!"; exit;
    }

    print 'ok';
    exit;
}

done_testing;
