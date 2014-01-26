set -e
for cmd in 'get' 'install' ; do
    go $cmd github.com/mattn/go-sqlite3
    go $cmd github.com/stevedonovan/luar
    go $cmd github.com/shavac/readline
done
