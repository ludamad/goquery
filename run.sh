#!/bin/bash
set -e

./compile.sh > .compile-log
export GOPATH=$GOPATH:"$(pwd)/goal":"$(pwd)/dependencies"
export LIBRARY_PATH=$LIBRARY_PATH:"$(pwd)/.libs"
goal/main main.lua
