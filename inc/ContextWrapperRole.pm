package inc::ContextWrapperRole;

use Moo::Role;
use namespace::clean;

use Path::Class qw(file);

use ZMQ::FFI::ContextRole;

my @ctx_methods = @{$Moo::Role::INFO{'ZMQ::FFI::ContextRole'}->{requires}};

requires $_."_tt" for @ctx_methods;

has zmqver => (
    is       => 'ro',
    required => 1,
);

has api_methods => (
    is      => 'ro',
    default => sub { \@ctx_methods },
);

has template => (
    is      => 'ro',
    default => sub { file('inc/ZmqContext.pm.tt') },
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
    return file("lib/ZMQ/FFI/$zmqver/Context.pm"),
}

sub wrappers {
    my ($self) = @_;

    my %wrappers;

    for my $ctx_method (@ctx_methods) {
        my $template_method = $ctx_method."_tt";
        $wrappers{$ctx_method} = $self->$template_method;
    }

    return \%wrappers;
}

1;
