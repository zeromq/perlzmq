#!/bin/bash -e

perl scripts/gen_dockerfiles.pl

docker build -f docker/Dockerfile.alpine-base \
             -t calid/alpine-base:latest \
             docker

parallel --will-cite \
    docker build -f docker/Dockerfile.{} \
                 -t calid/{}:alpine \
                 docker ::: zeromq2-x zeromq3-x zeromq4-x zeromq4-1 libzmq
