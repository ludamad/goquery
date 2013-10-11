set -e
export GOPATH=$GOPATH:$(pwd)
#go install go-future/types # TODO: Properly depend on this package. This is built here so that the typechecker can find it.
make

echo "DONE BUILDING"

DIR=src/goquery/
echo "***** ANALYZING $DIR ****"
./main $(find $DIR -name "*.go")
echo "FUNCTIONS:"
sqlite3 -line hello-world.db "SELECT * from functions"
echo "METHODS:"
sqlite3 -line hello-world.db "SELECT * from methods"
echo "IREQS:"
sqlite3 -line hello-world.db "SELECT * from interface_reqs"
echo "REFS:"
sqlite3 -line hello-world.db "SELECT * from refs"
echo "SOLVE:"
interface_types='(SELECT DISTINCT interface FROM interface_reqs)'
subexpr1='(SELECT COUNT(*) FROM interface_reqs INNER JOIN methods USING (name, type) WHERE receiver_type = T.name and interface = I.interface)'
subexpr2='(SELECT COUNT(*) FROM interface_reqs WHERE interface == I.interface)'
sqlite3 -line hello-world.db "
    SELECT T.name, I.interface as iname FROM types as T, $interface_types as I
    WHERE $subexpr1 == $subexpr2
"
