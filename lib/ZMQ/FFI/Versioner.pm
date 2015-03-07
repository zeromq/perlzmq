package ZMQ::FFI::Versioner;

use Moo::Role;

use ZMQ::FFI::Util qw(zmq_version);

requires q(soname);

has _version_parts => (
    is      => 'ro',
    lazy    => 1,
    default => sub { [zmq_version($_[0]->soname)] }
);

sub version {
    return @{$_[0]->_version_parts};
}

sub verstr {
    return join('.', $_[0]->version);
}

1;
