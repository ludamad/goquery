#!/bin/bash
set -e

./compile.sh > .compile-log
export GOPATH=$GOPATH:"$(pwd)/goal":"$(pwd)/dependencies":"/home/adomurad/go-install"
export LIBRARY_PATH=$LIBRARY_PATH:"$(pwd)/.libs"

goal/main isat1.lua $@
