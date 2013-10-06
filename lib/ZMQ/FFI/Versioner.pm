package ZMQ::FFI::Versioner;

use Moose;

use ZMQ::FFI::Util qw(zmq_version);

has soname => (
    is       => 'ro',
    required => 1,
);

has _version_parts => (
    is      => 'ro',
    lazy    => 1,
    default => sub { [zmq_version(shift->soname)] }
);

sub version {
    return @{shift->_version_parts};
}

__PACKAGE__->meta->make_immutable;
