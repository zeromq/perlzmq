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
        zmq_version
    )],
};

sub zmq_soname {
    # try to find a soname available on this system

    # .so symlink conventions are linker_name => soname => real_name
    # e.g. libzmq.so => libzmq.so.X => libzmq.so.X.Y.Z
    # Unfortunately not all distros follow this convention (Ubuntu).
    # So first we'll try the linker_name, then the sonames, and then give up
    my @sonames = qw(libzmq.so libzmq.so.3 libzmq.so.1);

    my $soname;
    FIND_SONAME:
    for (@sonames) {
        try {
            $soname = $_;

            my $zmq_version = FFI::Raw->new(
                $soname => 'zmq_version',
                FFI::Raw::void,
                FFI::Raw::ptr,  # major
                FFI::Raw::ptr,  # minor
                FFI::Raw::ptr   # patch
            );
        }
        catch {
            undef $soname;
        };

        last FIND_SONAME if $soname;
    }

    return $soname;
}

sub zmq_version {
    my $soname = shift;

    $soname //= zmq_soname();

    return unless $soname;

    my $zmq_version = FFI::Raw->new(
        $soname => 'zmq_version',
        FFI::Raw::void,
        FFI::Raw::ptr,  # major
        FFI::Raw::ptr,  # minor
        FFI::Raw::ptr   # patch
    );

    my ($major, $minor, $patch) = map { pack 'L!', $_ } (0, 0, 0);

    my @ptrs = map { unpack('L!', pack('P', $_)) } ($major, $minor, $patch);

    $zmq_version->(@ptrs);

    return map { unpack 'L!', $_ } ($major, $minor, $patch);
}

1;

__END__

=head1 SYNOPSIS

    use ZMQ::FFI::Util q(zmq_soname zmq_version)

    my $soname = zmq_soname();
    my ($major, $minor, $patch) = zmq_version($soname);

=head1 FUNCTIONS

=head2 zmq_soname

Tries to load libzmq.so, libzmq.so.1, libzmq.so.3 in that order, returning the
first one that was successful

=head2 ($major, $minor, $patch) = zmq_version([$soname])

return the libzmq version as the list C<($major, $minor, $patch)>. C<$soname>
can either be a filename available in the ld cache or the path to a library
file. If C<$soname> is not specified it is resolved using C<zmq_soname> above

=head1 SEE ALSO

=for :list
* L<ZMQ::FFI>
