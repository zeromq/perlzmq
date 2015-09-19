#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';

use FFI::TinyCC;
use FFI::Platypus;
use List::Util q(max);


my @versions;
my %zmq_constants;
for my $stable ('2-x','3-x','4-x','4-1') {
    chdir "$ENV{HOME}/git/zeromq$stable";

    for my $version (qx(git tag)) {
        chomp $version;
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
# between releases.
my @zmq_h_versions;
my @zmq_msg_sizes;

for my $stable ('2-x','3-x','4-x','4-1') {
    push @zmq_h_versions,
            "$ENV{HOME}/git/zeromq$stable/include/zmq.h";
}

push @zmq_h_versions, "$ENV{HOME}/git/libzmq/include/zmq.h";

my $ffi = FFI::Platypus->new();
for my $zmq_h (@zmq_h_versions) {
    my $tcc = FFI::TinyCC->new();
    $tcc->detect_sysinclude_path();

    $tcc->compile_string(qq{
        #include "$zmq_h"

        size_t sizeof_zmq_msg_t(void)
        {
            return sizeof(zmq_msg_t);
        }
    });

    my $f = $ffi->function(
        $tcc->get_symbol('sizeof_zmq_msg_t') => [] => 'size_t'
    );

    push @zmq_msg_sizes, $f->call();
}

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
zeromq3-x, zeromq4-x, and zeromq4-1 git repos at L<https://github.com/zeromq>.

=head1 SEE ALSO

=for :list
* L<ZMQ::FFI>

END

print $module;
