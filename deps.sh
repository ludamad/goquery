set -e
for cmd in 'install' ; do
    go $cmd github.com/mattn/go-sqlite3
    go $cmd github.com/stevedonovan/luar
    go $cmd github.com/shavac/readline
    go $cmd github.com/wendal/goyaml
done
