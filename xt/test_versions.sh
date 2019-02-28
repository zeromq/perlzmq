#!/bin/bash

set -e

function zmq_version {
    echo $(\
        PERL5LIB=lib:$PERL5LIB \
        perl -M'ZMQ::FFI::Util q(zmq_version)' \
        -E 'print join " ",zmq_version'\
    )
}

# This assumes libzmqs have been installed to /<zmq_version>/lib/libzmq.so,
# e.g. /zeromq2-x/lib/libzmq.so. A docker testing environment is provided
# that sets this up according, see the CONTRIBUTING section in the readme
function get_ld_dir {
    libzmq_dir="/$1/lib"

    if test -z "$libzmq_dir/libzmq.so"; then
        echo "No libzmq.so found in $libzmq_dir" >&2
        exit 1
    fi

    echo "$libzmq_dir"
}

function local_test {
    test_version=$1

    if [[ "$test_version" == "libzmq" ]]; then
        export LD_LIBRARY_PATH="$(get_ld_dir libzmq)"
    else
        export LD_LIBRARY_PATH="$(get_ld_dir zeromq$test_version)"
    fi

    echo -e "\nTesting zeromq" \
        "$(zmq_version | tr ' ' '.')"

    run_prove

    # extra test to check that out-of-order cleanup during global destruction
    # is handled and doesn't cause a program hang
    PERL5LIB=lib:$PERL5LIB timeout 1 perl xt/gc_global_destruction.pl \
        || (\
            echo "xt/gc_global_destruction.pl timed out during cleanup" >&2 \
            && exit 1 \
           )
}

function run_prove {
    prove -lvr t

    # test with different locale
    LANG=fr_FR.utf8 prove -lvr t
}

for v in "2-x" "3-x" "4-x" "4-1" "libzmq"
do
    local_test $v
done

# extra test to verify sonames arg is honored
LD_LIBRARY_PATH="$(get_ld_dir zeromq2-x)"
LD_LIBRARY_PATH+=":$(get_ld_dir zeromq3-x)"
export LD_LIBRARY_PATH

PERL5LIB=lib:$PERL5LIB perl xt/sonames.pl

