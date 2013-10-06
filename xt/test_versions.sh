#!/bin/bash

function travis_test {
    sudo rm -f /usr/lib/libzmq.so /usr/lib/x86_64-linux-gnu/libzmq.so

    case $1 in
        2)
            soname='libzmq.so.1'
            sodir='/usr/lib'
            ;;
        3)
            soname='libzmq.so.3'
            sodir='/usr/lib/x86_64-linux-gnu'
            ;;
    esac

    echo -e "\n$soname"

    sudo ln -svf $soname $sodir/libzmq.so
    sudo ldconfig -v
    ls -l $sodir

    # sanity test
    ver=$(perl -M'ZMQ::FFI::Util q(zmq_version)' -E 'say((zmq_version)[0])')
    if [[ $ver != $1 ]];
    then
        echo "unexpected version $ver != $1"
        exit 1
    fi

    prove -lvr t
}

function local_test {
    echo -e "\nlibzmq ${1}.x"
    export LD_LIBRARY_PATH="$HOME/git/zeromq$1-x/src/.libs"
    prove -lvr t
}

for v in 2 3
do
    if [[ -n $TRAVIS ]]
    then
        travis_test $v
    else
        local_test $v
    fi
done

