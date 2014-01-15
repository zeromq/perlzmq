package ZMQ::FFI::ZMQ4::Socket;
{
  $ZMQ::FFI::ZMQ4::Socket::VERSION = '0.07';
}

use Moo;
use namespace::autoclean;

use FFI::Raw;

extends q(ZMQ::FFI::SocketBase);

with q(ZMQ::FFI::SocketRole);

has zmq4_ffi => (
    is      => 'ro',
    lazy    => 1,
    builder => '_init_zmq4_ffi',
);

sub send {
    my ($self, $msg, $flags) = @_;

    $flags //= 0;

    $self->check_error(
        'zmq_send',
        $self->zmq4_ffi->{zmq_send}->(
            $self->_socket, $msg, length($msg), $flags
        )
    );
}

sub recv {
    my ($self, $flags) = @_;

    $flags //= 0;

    my $ffi = $self->ffi;

    my $msg_ptr = FFI::Raw::memptr(40); # large enough to hold zmq_msg_t

    $self->check_error(
        'zmq_msg_init',
        $ffi->{zmq_msg_init}->($msg_ptr)
    );

    my $msg_size =
        $self->zmq4_ffi->{zmq_msg_recv}->($msg_ptr, $self->_socket, $flags);

    $self->check_error('zmq_msg_recv', $msg_size);

    my $rv;
    if ($msg_size) {
        my $data_ptr    = $ffi->{zmq_msg_data}->($msg_ptr);
        my $content_ptr = FFI::Raw::memptr($msg_size);

        $ffi->{memcpy}->($content_ptr, $data_ptr, $msg_size);
        $rv = $content_ptr->tostr($msg_size);
    }
    else {
        $rv = '';
    }

    $ffi->{zmq_msg_close}->($msg_ptr);

    return $rv;
}

sub _init_zmq4_ffi {
    my $self = shift;

    my $ffi    = {};
    my $soname = $self->soname;

    $ffi->{zmq_send} = FFI::Raw->new(
        $soname => 'zmq_send',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # socket
        FFI::Raw::str, # message
        FFI::Raw::int, # length
        FFI::Raw::int  # flags
    );

    $ffi->{zmq_msg_recv} = FFI::Raw->new(
        $soname => 'zmq_msg_recv',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # msg ptr
        FFI::Raw::ptr, # socket
        FFI::Raw::int  # flags
    );

    return $ffi;
}

__PACKAGE__->meta->make_immutable();

__END__

=pod

=head1 NAME

ZMQ::FFI::ZMQ3::Socket

=head1 VERSION

version 0.07

=head1 AUTHOR

Dylan Cali <calid1984@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dylan Cali.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
