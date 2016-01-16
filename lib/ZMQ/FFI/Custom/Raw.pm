package ZMQ::FFI::Custom::Raw;

sub load {
    my ($soname) = @_;

    my $ffi    = FFI::Platypus->new( lib => $soname // 'libzmq.so' );
    my $target = caller;

    #
    # for get/set sockopt create ffi functions for each possible opt type
    #

    # int zmq_getsockopt(void *sock, int opt, void *val, size_t *len)

    $ffi->attach(
        ['zmq_getsockopt' => "${target}::zmq_getsockopt_binary"]
            => ['pointer', 'int', 'pointer', 'size_t*'] => 'int'
    );

    $ffi->attach(
        ['zmq_getsockopt' => "${target}::zmq_getsockopt_int"]
            => ['pointer', 'int', 'int*', 'size_t*'] => 'int'
    );

    $ffi->attach(
        ['zmq_getsockopt' => "${target}::zmq_getsockopt_int64"]
            => ['pointer', 'int', 'sint64*', 'size_t*'] => 'int'
    );

    $ffi->attach(
        ['zmq_getsockopt' => "${target}::zmq_getsockopt_uint64"]
            => ['pointer', 'int', 'uint64*', 'size_t*'] => 'int'
    );

    # int zmq_setsockopt(void *sock, int opt, const void *val, size_t len)

    $ffi->attach(
        ['zmq_setsockopt' => "${target}::zmq_setsockopt_binary"]
            => ['pointer', 'int', 'pointer', 'size_t'] => 'int'
    );

    $ffi->attach(
        ['zmq_setsockopt' => "${target}::zmq_setsockopt_int"]
            => ['pointer', 'int', 'int*', 'size_t'] => 'int'
    );

    $ffi->attach(
        ['zmq_setsockopt' => "${target}::zmq_setsockopt_int64"]
            => ['pointer', 'int', 'sint64*', 'size_t'] => 'int'
    );

    $ffi->attach(
        ['zmq_setsockopt' => "${target}::zmq_setsockopt_uint64"]
            => ['pointer', 'int', 'uint64*', 'size_t'] => 'int'
    );
}

1;
