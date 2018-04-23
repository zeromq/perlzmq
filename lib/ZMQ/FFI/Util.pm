package ZMQ::FFI::Util;

# ABSTRACT: zmq convenience functions

use strict;
use warnings;

use FFI::Platypus;
use Carp;

use Sub::Exporter -setup => {
    exports => [qw(
        zmq_soname
        zmq_version
        valid_soname
        current_tid
    )],
};

sub zmq_soname {
    my %args = @_;

    my $die = $args{die};

    # Try to find a soname available on this system
    #
    # Linux .so symlink conventions are linker_name => soname => real_name
    # e.g. libzmq.so => libzmq.so.X => libzmq.so.X.Y.Z
    # Unfortunately not all distros follow this convention (Ubuntu). So first
    # we'll try the linker_name, then the sonames.
    #
    # If Linux extensions fail also try platform specific
    # extensions (e.g. OS X) before giving up.
    my @sonames = qw(
        libzmq.so    libzmq.so.5    libzmq.so.4    libzmq.so.3    libzmq.so.1
        libzmq.dylib libzmq.4.dylib libzmq.3.dylib libzmq.1.dylib
    );

    my $soname;
    FIND_SONAME:
    for (@sonames) {
        $soname = $_;

        unless ( valid_soname($soname) ) {
            undef $soname;
        }

        if ($soname) {
            last FIND_SONAME;
        }
    }

    if ( !$soname && $die ) {
        croak
            qq(Could not load libzmq, tried:\n),
            join(', ', @sonames),"\n",
            q(Is libzmq on your loader path?);
    }

    return $soname;
}

sub zmq_version {
    my ($soname) = @_;

    $soname //= zmq_soname();

    return unless $soname;

    my $ffi = FFI::Platypus->new( lib => $soname, ignore_not_found => 1 );
    my $zmq_version = $ffi->function(
        'zmq_version',
        ['int*', 'int*', 'int*'],
        'void'
    );

    unless (defined $zmq_version) {
        croak   "Could not find zmq_version in '$soname'\n"
              . "Is '$soname' on your loader path?";
    }

    my ($major, $minor, $patch);
    $zmq_version->call(\$major, \$minor, \$patch);

    return $major, $minor, $patch;
}

sub valid_soname {
    my ($soname) = @_;

    my $ffi = FFI::Platypus->new( lib => $soname, ignore_not_found => 1 );
    my $zmq_version = $ffi->function(
        'zmq_version',
        ['int*', 'int*', 'int*'],
        'void'
    );

    return defined $zmq_version;
}

sub current_tid {
    if (eval 'use threads; 1') {
        require threads;
        threads->import();
        return threads->tid;
    }
    else {
        return -1;
    }
}

1;

__END__

=head1 SYNOPSIS

    use ZMQ::FFI::Util q(zmq_soname zmq_version)

    my $soname = zmq_soname();
    my ($major, $minor, $patch) = zmq_version($soname);

=head1 FUNCTIONS

=head2 zmq_soname([die => 0|1])

Tries to load the following sonames (in order):

    libzmq.so
    libzmq.so.5
    libzmq.so.4
    libzmq.so.3
    libzmq.so.1
    libzmq.dylib
    libzmq.4.dylib
    libzmq.3.dylib
    libzmq.1.dylib

Returns the name of the first one that was successful or undef. If you would
prefer exceptional behavior pass C<die =E<gt> 1>

=head2 ($major, $minor, $patch) = zmq_version([$soname])

return the libzmq version as the list C<($major, $minor, $patch)>. C<$soname>
can either be a filename available in the ld cache or the path to a library
file. If C<$soname> is not specified it is resolved using C<zmq_soname> above

If C<$soname> cannot be resolved undef is returned

=head1 SEE ALSO

=for :list
* L<ZMQ::FFI>
