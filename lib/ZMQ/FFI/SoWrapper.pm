package ZMQ::FFI::SoWrapper;

use Moo::Role;

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

has soname => (
    is       => 'ro',
    required => 1,
);

1;
