use strict;
use warnings;
use Test::More;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(:all);

subtest 'ctx options',
sub {
    my $ctx = ZMQ::FFI->new( threads => 42, max_sockets => 42 );

    is $ctx->get(ZMQ_IO_THREADS),  42, 'threads set to 42';
    is $ctx->get(ZMQ_MAX_SOCKETS), 42, 'max sockets set to 42';

    $ctx->set(ZMQ_IO_THREADS, 1);
    $ctx->set(ZMQ_MAX_SOCKETS, 1024);

    is $ctx->get(ZMQ_IO_THREADS),     1, 'threads set to 1';
    is $ctx->get(ZMQ_MAX_SOCKETS), 1024, 'max sockets set to 1024';
};

#subtest 'socket options',
#sub {
    #my @opts = qw(
        #sendhwm
        #rcvhwm
        #affinity
        #subscribe
        #unsubscribe
        #identity
        #rate
        #recovery_ivl
        #sndbuf
        #rcvbuf
        #linger
        #reconnect_ivl
        #reconnect_ivl_max
        #backlog'
        #maxmsgsize
        #multicast_hops
        #rcvtimeo
        #sndtimeo
        #ipv4only
        #delay_attach_on_connect
        #router_mandatory
        #xpub_verbose
        #tcp_keepalive
        #tcp_keepalive_idle
        #tcp_keepalive_cnt
        #tcp_keepalive_intvl
        #tcp_accept_filter
    #);

    #for my $opt (qw
    #is $s1->get_linger(), -1, 'got default linger';

    #$s1->set_linger(0);

    #ok defined($s1->get_linger()), 'linger is not undef';
    #is $s1->get_linger(), 0, 'linger set to 0';
#};

done_testing;
