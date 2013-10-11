package test3

import "fmt"

func foo(x int) int {
	return x
}

func bar() int {
	a := 1 + foo(2)
	b := foo(a)
	return foo(b)
}

func baz() {
	fmt.Print("")
}