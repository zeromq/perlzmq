#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';

my @versions;
my %zmq_constants;
for my $major (2,3,4) {
    chdir "$ENV{HOME}/git/zeromq$major-x";

    for my $version (qx(git tag)) {
        chomp $version;
        push @versions, $version;

        my %constants =
            map  { split '\s+' }
            grep { !/ZMQ_VERSION/ }
            grep { /\b(ZMQ_[^ ]+\s+\d+)/; $_ = $1; }
            qx(git show $version:include/zmq.h);

        while ( my ($constant,$value) = each %constants ) {

            if ( exists $zmq_constants{$constant} && $constant !~ m/DFLT/ ) {
                my $oldvalue   = $zmq_constants{$constant}->[0];
                my $oldversion = $zmq_constants{$constant}->[1];

                if ( $value != $oldvalue ) {
                    die "$constant redefined in $version: "
                        ."was $oldvalue since $oldversion, now $value";
                }
            }
            else {
                $zmq_constants{$constant} = [$value, $version];
            }
        }
    }
}

my @exports;
my @subs;

while ( my ($constant,$data) = each %zmq_constants ) {
    my $value = $data->[0];

    push @exports, $constant;
    push @subs, "sub $constant { $value }";
}

my $exports = join "\n", sort @exports;
my $subs    = join "\n", sort @subs;

my $date   = localtime;
my $first  = $versions[0];
my $latest = $versions[$#versions];

my $module = <<"END";
package ZMQ::FFI::Constants;

# ABSTRACT: Generated module of zmq constants. All constants, all versions.

# Module generated on $date
# Generated using ZMQ versions $first-$latest

use Exporter 'import';

\@EXPORT_OK = qw(
$exports
);

%EXPORT_TAGS = (all => [\@EXPORT_OK]);

$subs

1;

__END__

=head1 SYNOPSIS

    use ZMQ::FFI::Constants qw(ZMQ_LINGER ZMQ_FD);

    # or

    use ZMQ::FFI::Constants q(:all)

=head1 DESCRIPTION

This module includes every zmq constant from every stable version of zeromq.
Currently that is $first-$latest.  It was generated using the zeromq2-x,
zeromq3-x, and zeromq4-x git repos at L<https://github.com/zeromq>.

=head1 SEE ALSO

=for :list
* L<ZMQ::FFI>

END

print $module;
