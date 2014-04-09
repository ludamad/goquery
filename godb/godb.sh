#!/bin/bash
set -e

git_top="$(git rev-parse --show-toplevel)"

if [[ "$git_top" == "" ]] ; then
    echo "GoDB: Fatal, not in a 'git' directory."
    exit 2
fi

args="$@"

if [[ $args == "" ]] ; then
    echo "No arguments provided. Exitting."
    exit
fi

# Constants:
# Path to GoAL & godb source code:
SCRIPT_DIR=/home/adomurad/scripts/goquery/godb/
DB_NAME=$git_top/.git/godb/go_ast_dumps.db

# Go to git top-level:
cd $git_top
# Ensure godb folder exists:
mkdir -p "$git_top/.git/godb"

# Bash function to check for a flag in 'args' and remove it.
# Treats 'args' as one long string.
# Returns true if flag was removed.
function handle_flag(){
    flag=$1
    local new_args
    local got
    got=1 # False!
    for arg in $args ; do
        if [ $arg = $flag ] ; then
            args="${args/$flag/}"
            got=0 # True!
        else
            new_args="$new_args $arg"
        fi
    done
    args="$new_args"
    return $got # 1 == False!
}

function run() {
    $SCRIPT_DIR/goal $SCRIPT_DIR/main.lua $SCRIPT_DIR "sqlite3" $DB_NAME $@
}

function dump() {
    commit_name=$1
    if [[ "$commit_name" == "" ]] ; then commit_name=HEAD ; fi
    hash=$(git rev-parse --verify $commit_name)
    run dump $hash
}

# The typical command form:
function normal1arg() {
    commit_name=$2
    if [[ "$commit_name" == "" ]] ; then commit_name=HEAD ; fi
    hash=$(git rev-parse --verify $commit_name)
    run $1 $hash
}

# TODO: For now, only compare HEAD and HEAD^
function diff() {
    hash1=$(git rev-parse --verify HEAD^)
    hash2=$(git rev-parse --verify HEAD)
    run diff $hash1 $hash2
}

function man() {
    sqliteman $DB_NAME
}

function init() {
    if [ ! -f ".git/hooks/post-commit" ] ; then
        echo "$SCRIPT_DIR/godb.sh dump" > ".git/hooks/post-commit"
        chmod a+x ".git/hooks/post-commit"
    else
        echo "Not touching existing .git/hooks/post-commit!"
    fi
    # Also begin by dumping current commit:
    dump
}

if handle_flag "init" ; then
    init
elif handle_flag "deinit" || handle_flag "clear" ; then
    echo "Removing database. Please decide if you wish to remove .git/hooks/post-commit."
    rm $DB_NAME
elif handle_flag "diff" ; then
    diff
elif handle_flag "man" ; then
    man
else
    # The typical command form:
    normal1arg $@
fi
