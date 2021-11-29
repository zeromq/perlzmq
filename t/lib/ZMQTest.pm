package ZMQTest;
# ABSTRACT: Test helper library

=head1 CLASS METHODS

=head2 platform_can_fork

Returns true if platform can use L<fork(2)> syscall.

Returns false on C<MSWin32> which does not have a real L<fork(2)>.

=cut
sub platform_can_fork {
	return $^O ne 'MSWin32';
}

=head2 platform_can_sigaction

Returns true if platform can use L<Sys::SigAction>.

Returns false on C<MSWin32> which does not have L<sigaction(2)>.

=cut
sub platform_can_sigaction {
	return $^O ne 'MSWin32';
}

=head2 platform_zmq_fd_sockopt_is_fd

Returns true if the ZeroMQ socket option C<ZMQ_FD> is a C runtime file
descriptor (which is an C<int>).

Returns false on C<MSWin32> where C<ZMQ_FD> is of type C<SOCKET>
(which is a C<uint64>).

=cut
sub platform_zmq_fd_sockopt_is_fd {
	return $^O ne 'MSWin32';
}

=head2 platform_can_transport_zmq_ipc

Returns true if platform can use L<zmq_ipc(7)> transport.

This is currently false on systems such as C<MSWin32> because they do not
support Unix domain sockets.

=cut
sub platform_can_transport_zmq_ipc {
	return $^O ne 'MSWin32';
}

=head2 endpoint

  ZMQTest->endpoint($name)

Returns an appropriate endpoint string that is supported on the current
platform.

=cut
sub endpoint {
	my ($class, $name) = @_;
	if( $class->platform_can_transport_zmq_ipc ) {
		return "ipc:///tmp/$name";
	} else {
		return "inproc://$name";
	}
}

1;
