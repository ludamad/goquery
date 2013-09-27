set -e
go build main.go
for i in test-files/*.go ; do
    ./main $i
    echo "** Interface satisfactions for file $i:" 

    interface_types='(SELECT DISTINCT interface FROM interface_reqs)'
    subexpr1='(SELECT COUNT(*) FROM interface_reqs INNER JOIN methods USING (name, type) WHERE receiver_type = T.name and interface = I.interface)'
    subexpr2='(SELECT COUNT(*) FROM interface_reqs WHERE interface == I.interface)'
    sqlite3 hello-world.db -line "
        SELECT T.name, I.interface as iname FROM types as T, $interface_types as I
        WHERE $subexpr1 == $subexpr2
    "
done
