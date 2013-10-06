#!/bin/bash

function travis_test {
    echo -e "\nlibzmq ${1}.x"
    sudo ln -svf /usr/lib/libzmq.so.$1 /usr/lib/libzmq.so
    sudo ldconfig -v
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

