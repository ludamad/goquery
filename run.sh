set -e
export GOPATH=$GOPATH:$(pwd)
go install go-future/types # TODO: Properly depend on this package. This is built here so that the typechecker can find it.
go build src/main.go
./main $@
