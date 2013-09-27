set -e
go build main.go
./main 'test-file.go'
# Print database contents
echo "** METHODS:"
sqlite3 hello-world.db -line 'select * from methods'

echo "** INTERFACE REQUIREMENTS:"
sqlite3 hello-world.db -line 'select * from interface_reqs'

echo "** TYPE DECLARATIONS:"
sqlite3 hello-world.db -line 'select * from types'

echo "** QUERY ALL INTERFACE SATISFACTIONS:" 

interface_types='(SELECT DISTINCT interface FROM interface_reqs)'
subexpr1='(SELECT COUNT(*) FROM interface_reqs INNER JOIN methods USING (name, type) WHERE receiver_type = T.name and interface = I.interface)'
subexpr2='(SELECT COUNT(*) FROM interface_reqs WHERE interface == I.interface)'
sqlite3 hello-world.db -line "
    SELECT T.name, I.interface as iname FROM types as T, $interface_types as I
    WHERE $subexpr1 == $subexpr2
"
