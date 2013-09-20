set -e
go build main.go
./main main.go
# Print database contents
echo "-- hello-world.db contents --"
sqlite3 hello-world.db -line 'select * from methods'
