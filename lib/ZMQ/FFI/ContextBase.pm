package ZMQ::FFI::ContextBase;

use Moo;
use namespace::autoclean;

use Carp;

with qw(
    ZMQ::FFI::ContextRole
    ZMQ::FFI::ErrorHandler
    ZMQ::FFI::Versioner
);

# real underlying zmq ctx pointer
has _ctx => (
    is      => 'rw',
    default => -1,
);

sub get {
    croak 'unimplemented in base class';
}

sub set {
    croak 'unimplemented in base class';
}

sub socket {
    croak 'unimplemented in base class';
}

sub destroy {
    croak 'unimplemented in base class';
}

sub DEMOLISH {
    my $self = shift;

    unless ($self->_ctx == -1) {
        $self->destroy();
    }
}

__PACKAGE__->meta->make_immutable();

