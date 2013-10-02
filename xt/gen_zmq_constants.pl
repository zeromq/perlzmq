#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';

my %zmq_constants;
for my $v (2,3) {
    chdir "$ENV{HOME}/git/zeromq$v-x";

    for my $t (qx(git tag)) {
        chomp $t;
        say "Getting constants for $t";

        my %c =
            map  { split ' ' }
            grep { !/ZMQ_VERSION/ }
            grep { /\b(ZMQ_[^ ]+ \d+)/; $_ = $1; }
            qx(git show $t:include/zmq.h);

        while ( my ($k,$v) = each %c ) {
            if ( exists $zmq_constants{$k} && $zmq_constants{$k} != $v ) {
                die "$k redefined in $t";
            }

            $zmq_constants{$k} = $v;
        }
    }
}

