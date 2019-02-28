#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';

use Path::Class qw(file dir);
use List::Util q(max);
use autodie qw(system);

my $constants_pm = 'lib/ZMQ/FFI/Constants.pm';
say "Generating '$constants_pm'";
$constants_pm = file($constants_pm)->absolute;

my @versions;
my %zmq_constants;
my $builddir = dir("$ENV{HOME}/.zmq-ffi");
my @repos = map { "zeromq$_" } qw(2-x 3-x 4-x 4-1);
push @repos, 'libzmq';

# We need to iterate each stable version of each zmq mainline to get the
# complete set of all zeromq constants across versions. Some sanity checking
# is also done to verify constants weren't redefined in subsequent versions
for my $r (@repos) {
    say "\nGetting releases for $r";

    my $repo_dir = $builddir->subdir("$r");

    if ( ! -d "$repo_dir" ) {
        say "$repo_dir doesn't exist";
        my $repo_url = "https://github.com/zeromq/$r.git";
        say "Cloning $repo_url to $repo_dir";
        system("git clone -q $repo_url $repo_dir");
    }

    chdir "$repo_dir";

    for my $version (qx(git tag)) {
        chomp $version;
        say "Getting constants for $version";
        push @versions, $version;

        my %constants =
            map  { split '\s+' }
            grep { !/ZMQ_VERSION/ }
            grep { /\b(ZMQ_[^ ]+\s+(0x)?\d+)/; $_ = $1; }
            qx(git show $version:include/zmq.h);

        while ( my ($constant,$value) = each %constants ) {

            # handle hex values
            if ( $value =~ m/^0x/ ) {
                $value = hex($value);
            }

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

    chdir '..'
}

my @exports;
my @subs;

while ( my ($constant,$data) = each %zmq_constants ) {
    my $value = $data->[0];

    push @exports, $constant;
    push @subs, "sub $constant { $value }";
}


# Also add dynamically generated zmq_msg_t size.  we use 2x the largest
# size of zmq_msg_t among all zeromq versions, including dev. This
# should hopefully be large enough to accomodate fluctuations in size
# between releases. Note this assumes the generated zmq_msg_sizes file exists
my @zmq_msg_sizes = file("$builddir/zmq_msg_size/zmq_msg_sizes")
                        ->slurp(chomp => 1);
my $zmq_msg_size = 2 * max(@zmq_msg_sizes);
push @exports, 'zmq_msg_t_size';
push @subs, "sub zmq_msg_t_size { $zmq_msg_size }";

my $exports = join "\n", sort @exports;
my $subs    = join "\n", sort @subs;

my $date   = localtime;
my $first  = $versions[0];
my $latest = $versions[$#versions];

my $module = <<"END";
package ZMQ::FFI::Constants;

# ABSTRACT: Generated module of zmq constants. All constants, all versions.

# Generated using ZMQ versions $first-$latest

use strict;
use warnings;

use Exporter 'import';

our \@EXPORT_OK = qw(
$exports
);

our %EXPORT_TAGS = (all => [\@EXPORT_OK]);

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
zeromq3-x, zeromq4-x, zeromq4-1, and libzmq git repos at
L<https://github.com/zeromq>.

=head1 SEE ALSO

=for :list
* L<ZMQ::FFI>

END

say "\nWriting module file";
$constants_pm->spew($module);
say "Done!\n";
