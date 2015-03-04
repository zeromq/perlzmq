package ZMQ::FFI::ErrorHelper;

use Carp;
use FFI::Platypus;
use ZMQ::FFI::Util qw(zmq_version);

use Moo;
use namespace::clean;

has soname => (
    is       => 'ro',
    required => 1,
);

has _err_ffi => (
    is      => 'ro',
    lazy    => 1,
    builder => '_init_err_ffi',
);

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

sub bad_version {
    my ($self, $msg, $use_carp) = @_;

    my $verstr = join ".", zmq_version($self->soname);

    if ($use_carp) {
        croak   "$msg\n"
              . "your version: $verstr";
    }
    else {
        die   "$msg\n"
            . "your version: $verstr";

    }
}

sub fatal {
    my ($self, $func) = @_;

    my $ffi = $self->_err_ffi;

    my $errno  = $ffi->{zmq_errno}->();
    my $strerr = $ffi->{zmq_strerror}->($errno);

    confess "$func: $strerr";
}

sub _init_err_ffi {
    my $self = shift;

    my $soname   = $self->soname;
    my $ffi_href = {};
    my $ffi      = FFI::Platypus->new( lib => $soname );

    $ffi_href->{zmq_errno} = $ffi->function(
        'zmq_errno',
        [] => 'int'
    );

    $ffi_href->{zmq_strerror} = $ffi->function(
        'zmq_strerror',
        ['int'] => 'string'
    );

    return $ffi_href;
}

1;
