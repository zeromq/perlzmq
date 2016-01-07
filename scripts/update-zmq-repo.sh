#!/bin/bash -e

repo=$1

test -z "$repo" && echo "usage: $(basename $0) <zmqrepo>" && exit 1

mkdir -p $HOME/git

echo "Updating $repo lib"

repodir="$HOME/git/$repo"

if [ ! -d $repodir ]; then
    git clone https://github.com/zeromq/${repo} $repodir
    cd $repodir
    ./autogen.sh
    ./configure && make -j8
else
    cd $repodir

    hbefore="$(git show -s --pretty=format:%h)"

    git pull

    hafter="$(git show -s --pretty=format:%h)"

    libzmq="$(find -type l -name libzmq.so)"

    if [[ "$hbefore" != "$hafter" || -z "$libzmq" ]]; then
        ./autogen.sh
        ./configure && make -j8
    fi

fi
