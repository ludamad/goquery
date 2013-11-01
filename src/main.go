package main

import (
	"fmt"
	"goal"
)

func main() {
	allPassed := goal.RunTests("src/tests")

	if !allPassed {
		fmt.Printf("Error: Not all tests have passed!\n")
	} else {
		fmt.Printf("All tests passed.\n")
	}
}
