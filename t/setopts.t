use strict;
use warnings;
use Test::More;

use ZMQ::FFI;


my $ctx = ZMQ::FFI->new( threads => 42, max_sockets => 42 );

is $ctx->get_threads(),     42, 'threads set to 42';
is $ctx->get_max_sockets(), 42, 'max sockets set to 42';

$ctx->set_threads(1);
$ctx->set_max_sockets(1024);

is $ctx->get_threads(),        1, 'threads set to 1';
is $ctx->get_max_sockets(), 1024, 'max sockets set to 1024';

#is $s1->get_linger(), -1, 'got default linger';

#$s1->set_linger(0);

#ok defined($s1->get_linger()), 'linger is not undef';
#is $s1->get_linger(), 0, 'linger set to 0';

done_testing;
