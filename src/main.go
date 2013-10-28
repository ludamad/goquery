package main

import (
	"fmt"
	"goal"
)

func main() {
	allPassed := goal.RunTests("src/tests")

	if !allPassed {
		fmt.Printf("Not all tests have passed!\n")
	}
}
