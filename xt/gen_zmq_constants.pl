#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';

my @versions;
my %zmq_constants;
for my $v (2,3) {
    chdir "$ENV{HOME}/git/zeromq$v-x";

    for my $t (qx(git tag)) {
        chomp $t;
        push @versions, $t;

        my %c =
            map  { split '\s+' }
            grep { !/ZMQ_VERSION/ }
            grep { /\b(ZMQ_[^ ]+\s+\d+)/; $_ = $1; }
            qx(git show $t:include/zmq.h);

        while ( my ($k,$v) = each %c ) {
            if ( exists $zmq_constants{$k} && $zmq_constants{$k} != $v ) {
                die "$k redefined in $t";
            }

            $zmq_constants{$k} = $v;
        }
    }
}

my @exports;
my @subs;

while ( my ($k,$v) = each %zmq_constants ) {
    push @exports, $k;
    push @subs, "sub $k { $v }";
}

my $exports = join "\n", sort @exports;
my $subs    = join "\n", sort @subs;

my $date   = localtime;
my $first  = $versions[0];
my $latest = $versions[$#versions];

my $module = <<"END";
package ZMQ::FFI::Constants;

# Module generated on $date
# Generated using ZMQ versions $first-$latest

use Exporter 'import';

\@EXPORT_OK = qw(
$exports
);

%EXPORT_TAGS = (all => [\@EXPORT_OK]);

$subs

1;
END

print $module;
