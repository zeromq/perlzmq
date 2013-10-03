#!/bin/bash

repodir="$HOME/git"

for v in 2 3
do
    echo -e "\nlibzmq ${v}.x"

    export LD_LIBRARY_PATH="$repodir/zeromq$v-x/src/.libs"
    prove -lvr
done
