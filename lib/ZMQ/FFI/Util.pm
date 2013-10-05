package ZMQ::FFI::Util;

# ABSTRACT: zmq convenience functions

use strict;
use warnings;

use FFI::Raw;
use Carp;
use Try::Tiny;

use Sub::Exporter -setup => {
    exports => [qw(
        zmq_soname
        zcheck_error
        zcheck_null
        zmq_version
    )],
};

our $SONAME;

my $zmq_errno;
my $zmq_strerror;
my $zmq_version;

BEGIN {
    # .so symlink conventions are linker_name => soname => real_name
    # e.g. libzmq.so => libzmq.so.X => libzmq.so.X.Y.Z
    # Unfortunately not all distros follow this convention (Ubuntu).
    # So first we'll try the linker_name, then the sonames, and then give up
    my @sonames = qw(libzmq.so libzmq.so.3 libzmq.so.2);

    FIND_SONAME:
    for (@sonames) {
        try {
            $SONAME = $_;

            $zmq_errno = FFI::Raw->new(
                $SONAME => 'zmq_errno',
                FFI::Raw::int # returns errno
                # void
            );

            $zmq_strerror = FFI::Raw->new(
                $SONAME => 'zmq_strerror',
                FFI::Raw::str,  # returns error str
                FFI::Raw::int   # errno
            );

            $zmq_version = FFI::Raw->new(
                $SONAME => 'zmq_version',
                FFI::Raw::void,
                FFI::Raw::ptr,  # major
                FFI::Raw::ptr,  # minor
                FFI::Raw::ptr   # patch
            );
        }
        catch {
            undef $SONAME;
        };

        last FIND_SONAME if $SONAME;
    }

    unless ($SONAME) {
        croak
            q(Could not load libzmq, tried: ).
            join(', ', @sonames)."\n".
            q(Is libzmq on your ld path?);
    }
}

sub zmq_soname {
    return $SONAME;
}

sub zcheck_error {
    my ($func, $rc) = @_;

    if ( $rc == -1 ) {
        zdie($func);
    }
}

sub zcheck_null {
    my ($func, $obj) = @_;

    unless ($obj) {
        zdie($func);
    }
}

sub zdie {
    my ($func) = @_;

    croak "$func: ".$zmq_strerror->($zmq_errno->());
}

sub zmq_version {
    my ($major, $minor, $patch) = map { pack 'L!', $_ } (0, 0, 0);

    my @ptrs = map { unpack('L!', pack('P', $_)) } ($major, $minor, $patch);

    $zmq_version->(@ptrs);

    return map { unpack 'L!', $_ } ($major, $minor, $patch);
}

1;

__END__

=head1 SYNOPSIS

    use ZMQ::FFI::Util q(zmq_version)

    my ($major, $minor, $patch) = zmq_version();

=head1 SEE ALSO

=for :list
* L<ZMQ::FFI>
