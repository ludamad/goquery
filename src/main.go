package main

import (
	"fmt"
	"goal"
	"flag"
)

func main() {
	testToRun := flag.Int("test", -1, "the test number to run")
	flag.Parse()

	failed, ran := goal.RunTests("src/tests", *testToRun)

	if failed != 0 {
		fmt.Printf("Error: Not all tests have passed! %d of %d tests failed.\n", failed, ran)
	} else {
		fmt.Printf("All %d tests passed.\n", ran)
	}
}
