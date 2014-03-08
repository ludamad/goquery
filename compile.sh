#!/bin/bash
#
# NOTE: The user *must* ensure our library versions gets picked up first, for the following reasons:
# - The SQLlite3 library is source packed after it broke compatibility in a release (up to date as of March 7th, 2013)
# - The Lua library is source packed simply to point to our in-tree LuaJIT
# - The go/types library is shamefully hacked because the author was unable to map FuncDecl to FuncType after a new release

set -e

## Helpers:
function make_lib() {
    prev="$(pwd)"
    cd "$1"
    if [[ -e /proc/cpuinfo ]] ; then cores=$(grep -c ^processor /proc/cpuinfo)
    else cores=4 ; fi # Guess
    make -j$((cores+1))
    if [[ "$2" != "" ]] ; then 
        cp "$2" "$prev/.libs/"
    fi
    cd "$prev" 
}


## Environment set up:
export GOPATH=$GOPATH:"$(pwd)/goal":"$(pwd)/dependencies" 
export LIBRARY_PATH=$LIBRARY_PATH:"$(pwd)/.libs"

## Library building:
mkdir -p ".libs"

# Install necessary lua files in .libs:
cp "./goal/goal.lua" "./.libs/"
cp ./goal/extra/*.lua "./.libs/"

cp -r "./dependencies/lua-repl/repl/" "./.libs/"
cp "./dependencies/lua-repl/repl.lua" "./.libs/repl.lua"

# Install necessary library files in .libs:
make_lib "./dependencies/lua-yaml" "yaml.so"
make_lib "./dependencies/lua-linenoise" "linenoise.so"
make_lib "./dependencies/LuaJIT-2.0.2" "src/libluajit.a"

# Rename for golua:
cp ".libs/libluajit.a" ".libs/liblua.a" 

# Go dependencies:
for pkg in \
    github.com/mattn/go-sqlite3 \
    github.com/stevedonovan/luar \
    github.com/shavac/readline \
    github.com/lib/pq 
do
    go install $pkg
done

## Compiling GoAL itself:
make_lib ./goal 
