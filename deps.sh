set -e
sudo yum install readline-devel
for cmd in 'get' 'install' ; do
    go $cmd github.com/mattn/go-sqlite3
    go $cmd github.com/stevedonovan/luar
    #NOTE: I had to jiggle golua manually to link to LuaJIT. YMMV.
    go $cmd github.com/shavac/readline
done
