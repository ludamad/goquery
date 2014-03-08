#!/bin/bash
set -e

./compile.sh
cd goal
export GOPATH=$GOPATH:"$(pwd)/../dependencies"
export LIBRARY_PATH=$LIBRARY_PATH:"$(pwd)/.libs"
./main --tests $@
