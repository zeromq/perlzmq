#!/bin/bash -e

docker container prune -f
docker image prune -f
docker images -q --filter dangling=true | xargs docker rmi
