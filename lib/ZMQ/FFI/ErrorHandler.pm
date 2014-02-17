package ZMQ::FFI::ErrorHandler;

use Moo::Role;

requires q(soname);

# ZMQ::FFI::ErrorHelper instance
has error_helper => (
    is       => 'ro',
    required => 1,
    handles => [qw(
        check_error
        check_null
    )],
);

1;
