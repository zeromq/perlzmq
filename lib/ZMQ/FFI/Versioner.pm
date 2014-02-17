package ZMQ::FFI::Versioner;

use Moo::Role;

use ZMQ::FFI::Util qw(zmq_version);

requires q(soname);

has _version_parts => (
    is      => 'ro',
    lazy    => 1,
    default => sub { [zmq_version(shift->soname)] }
);

sub version {
    return @{shift->_version_parts};
}

1;
