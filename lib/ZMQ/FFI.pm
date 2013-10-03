package ZMQ::FFI;

use ZMQ::FFI::Util qw(zmq_version);

sub new {
    my $self = shift;

    my ($major) = zmq_version();

    if ($major == 2) {
        require ZMQ::FFI::ZMQ2::Context;
        return ZMQ::FFI::ZMQ2::Context->new(@_);
    }
    else {
        require ZMQ::FFI::ZMQ3::Context;
        return ZMQ::FFI::ZMQ3::Context->new(@_);
    }
};

1;
