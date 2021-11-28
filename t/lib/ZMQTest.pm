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

1;
