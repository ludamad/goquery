set -e
export GOPATH=$GOPATH:$(pwd)

go install go-future/types # TODO: Properly depend on this package. 
make -j5
cd src/lua-yaml
make -j5
cp yaml.so ../../luascripts/yaml.so
cd ../../luascripts
../main main.lua $@
