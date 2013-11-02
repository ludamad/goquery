package main

import (
	"fmt"
	"goal"
)

func main() {
	failed, ran := goal.RunTests("src/tests")

	if failed != 0 {
		fmt.Printf("Error: Not all tests have passed! %d of %d tests failed.\n", failed, ran)
	} else {
		fmt.Printf("All %d tests passed.\n", ran)
	}
}
