#include <zmq.h>
#include <stdio.h>

int main(void)
{
    printf("%zu\n", sizeof(zmq_msg_t));
}
