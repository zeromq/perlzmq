use Test::More;
use Test::Warnings;
use strict;
use warnings;

use ZMQ::FFI;
use ZMQ::FFI::ZMQ2::Context;
use ZMQ::FFI::ZMQ2::Socket;
use ZMQ::FFI::ZMQ3::Context;
use ZMQ::FFI::ZMQ3::Socket;

use ZMQ::FFI::Constants qw(ZMQ_REQ);
use ZMQ::FFI::Util qw(zmq_version);

my @gc_stack;

my ($major) = zmq_version;
if ($major == 2) {
    no warnings q/redefine/;

    local *ZMQ::FFI::ZMQ2::Context::destroy = sub {
        my ($self) = @_;
        $self->context_ptr(-1);
        push @gc_stack, 'destroy'
    };

    local *ZMQ::FFI::ZMQ2::Socket::close = sub {
        my ($self) = @_;
        $self->socket_ptr(-1);
        push @gc_stack, 'close'
    };

    use warnings;

    mkcontext();

    is_deeply
        \@gc_stack,
        ['close', 'close', 'close', 'destroy'],
        q(socket reaped before context);
}
else {
    no warnings q/redefine/;

    local *ZMQ::FFI::ZMQ3::Context::destroy = sub {
        my ($self) = @_;
        $self->context_ptr(-1);
        push @gc_stack, 'destroy'
    };

    local *ZMQ::FFI::ZMQ3::Socket::close  = sub {
        my ($self) = @_;
        $self->socket_ptr(-1);
        push @gc_stack, 'close'
    };

    use warnings;

    mkcontext();

    is_deeply
        \@gc_stack,
        ['close', 'close', 'close', 'destroy'],
        q(sockets closed before context destroyed);
}

sub mkcontext {
    my $context = ZMQ::FFI->new();

    mksockets($context);
    return;
}

sub mksockets {
    my ($context) = @_;

    my $s1 = $context->socket(ZMQ_REQ);
    my $s2 = $context->socket(ZMQ_REQ);
    my $s3 = $context->socket(ZMQ_REQ);

    return;
}

done_testing;
