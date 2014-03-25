set -e

./compile.sh
rm -rf godb/.libs godb/goal

cp -r .libs godb/.libs
cp goal/main godb/goal
