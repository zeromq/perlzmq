use strict;
use warnings;
use Test::More;

is $s1->get_linger(), -1, 'got default linger';

$s1->set_linger(0);

ok defined($s1->get_linger()), 'linger is not undef';
is $s1->get_linger(), 0, 'linger set to 0';

done_testing;
