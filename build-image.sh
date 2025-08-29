#!/bin/bash

set -euo pipefail

mkdir -p bare/var

c=`docker create ruby:alpine`
trap 'if docker inspect $c >/dev/null 2>/dev/null ; then docker rm $c >/dev/null ; fi' 0

docker export $c > bare/var/ruby-alpine-root.tar.gz

docker build --quiet --tag bare-image ./bare
