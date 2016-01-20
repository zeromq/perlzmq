package inc::SocketWrapperRole;

use Moo::Role;
use namespace::clean;

use Path::Class qw(file);

use ZMQ::FFI::SocketRole;

my @socket_methods = @{$Moo::Role::INFO{'ZMQ::FFI::SocketRole'}->{requires}};

requires $_."_tt" for @socket_methods;

has zmqver => (
    is       => 'ro',
    required => 1,
);

has api_methods => (
    is      => 'ro',
    default => sub { \@socket_methods },
);

has template => (
    is      => 'ro',
    default => sub { file('inc/ZmqSocket.pm.tt') },
);

has target => (
    is => 'lazy',
);

has lib_imports => (
    is  => 'ro',
    default => '',
);

sub _build_target {
    my ($self) = @_;

    my $zmqver = $self->zmqver;
    return file("lib/ZMQ/FFI/$zmqver/Socket.pm"),
}

sub wrappers {
    my ($self) = @_;

    my %wrappers;

    for my $socket_method (@socket_methods) {
        my $template_method = $socket_method."_tt";
        $wrappers{$socket_method} = $self->$template_method;
    }

    return \%wrappers;
}

1;
