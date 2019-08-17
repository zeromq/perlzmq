use 5.012;
use warnings;

use ZMQ::FFI qw(ZMQ_SUB);
use Try::Tiny;

my $count = 0;

$SIG{USR1} = sub {
    say "received $count messages";
};

$SIG{USR2} = sub {
    say "resetting message count";
    $count = 0;
};

say "'kill -USR1 $$' to print current message count";
say "'kill -USR2 $$' to reset message count";

my $ctx = ZMQ::FFI->new();
my $s = $ctx->socket(ZMQ_SUB);
$s->connect('ipc:///tmp/zmq-bench-c');
$s->connect('ipc:///tmp/zmq-bench-xs');
$s->connect('ipc:///tmp/zmq-bench-ffi');
$s->subscribe('');

my $r;
while (1) {
    try {
        $r = $s->recv();
        $count++;
    }
    catch {
        croak $_ unless $_ =~ m/Interrupted system call/;
    };
}
