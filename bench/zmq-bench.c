#include <zmq.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>

int main(void)
{
    void *ctx = zmq_ctx_new();
    assert(ctx);

    void *socket = zmq_socket(ctx, ZMQ_PUB);
    assert(socket);

    assert( -1 != zmq_bind(socket, "ipc:///tmp/zmq-bench-c") );

    int major, minor, patch;
    zmq_version(&major, &minor, &patch);

    printf("C ZMQ Version: %d.%d.%d\n", major, minor, patch);

    int i;
    for ( i = 0; i < (10 * 1000 * 1000); i++ ) {
        assert( -1 != zmq_send(socket, "c", 1, 0) );
    }

    printf("Sent %d messages\n", i);

    zmq_close(socket);
    zmq_ctx_destroy(ctx);
}
