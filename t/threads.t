
use strict;
use warnings;

use Test::More;

use Time::HiRes qw(usleep);

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ ZMQ_ROUTER);

my $THREAD_COUNT = 10;

my $can_use_threads = eval 'use threads; 1';
if (!$can_use_threads) {
    plan skip_all => 'This Perl not build to support threads';
}
else {
    # three tests per thread plus NoWarnings test
    plan tests => $THREAD_COUNT * 3 + 1;
    require Test::NoWarnings;
    Test::NoWarnings->import();
}

sub worker_task {
    my $id = shift;

    my $context = ZMQ::FFI->new();
    my $worker  = $context->socket(ZMQ_REQ);

    $worker->set_identity("worker-$id");
    $worker->connect('tcp://localhost:5671');

    $worker->send("ohhai from worker-$id");

    my $reply = $worker->recv();
    return ($reply, "worker-$id");
}

my $context = ZMQ::FFI->new();
my $broker  = $context->socket(ZMQ_ROUTER);

$broker->bind('tcp://*:5671');

my @thr;
for (1..$THREAD_COUNT) {
    push @thr, threads->create('worker_task', $_);
}

for (1..$THREAD_COUNT) {
    my ($identity, undef, $msg) = $broker->recv_multipart();

    like $identity, qr/^worker-\d\d?$/,
                    "got child thread identity '$identity'";

    is $msg, "ohhai from $identity",
             "got child thread '$identity' hello message";

    $broker->send_multipart([$identity, '', "goodbye $identity"]);
}

for my $thr (@thr) {
    my ($reply, $identity) = $thr->join();
    is $reply, "goodbye $identity",
               "'$identity' got parent thread goodbye message";
}
