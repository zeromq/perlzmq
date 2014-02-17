package ZMQ::FFI::SoWrapper;

# common helpers for working with zeromq ffi bindings

use Moo::Role;

use ZMQ::FFI::ErrorHandler;
use ZMQ::FFI::Versioner;

has soname => (
    is       => 'ro',
    required => 1,
);

has _err_handler => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return ZMQ::FFI::ErrorHandler->new(
            soname => shift->soname
        );
    },
    handles => [qw(
        check_error
        check_null
    )],
);

has _versioner => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return ZMQ::FFI::Versioner->new(
            soname => shift->soname
        );
    },
    handles => [qw(version)],
);

1;
