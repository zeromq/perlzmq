package ZMQ::FFI::ErrorHandler;

use Moo;
use namespace::autoclean;

use Carp;
use FFI::Raw;

has soname => (
    is       => 'ro',
    required => 1,
);

sub BUILD {
    shift->_init_ffi();
}

my $zmq_errno;
my $zmq_strerror;

sub _init_ffi {
    my $soname = shift->soname;

    $zmq_errno = FFI::Raw->new(
        $soname => 'zmq_errno',
        FFI::Raw::int # returns errno
        # void
    );

    $zmq_strerror = FFI::Raw->new(
        $soname => 'zmq_strerror',
        FFI::Raw::str,  # returns error str
        FFI::Raw::int   # errno
    );
}

sub check_error {
    my ($self, $func, $rc) = @_;

    if ( $rc == -1 ) {
        $self->fatal($func);
    }
}

sub check_null {
    my ($self, $func, $obj) = @_;

    unless ($obj) {
        $self->fatal($func);
    }
}

sub fatal {
    my ($self, $func) = @_;

    confess "$func: ".$zmq_strerror->($zmq_errno->());
}

__PACKAGE__->meta->make_immutable;
