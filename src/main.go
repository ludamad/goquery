package main

import (
	"flag"
	"fmt"
	"goal"
	"os"
)


func main() {
 	runTests := flag.Bool("tests", false, "whether to run tests (only)")
	testToRun := flag.Int("test", -1, "the test number to run")

	flag.Parse()

	if *runTests {
		failed, ran := goal.RunTests("tests", *testToRun)

		if failed != 0 {
			fmt.Printf("Error: Not all tests have passed! %d of %d tests failed.\n", failed, ran)
		} else {
			fmt.Printf("All %d tests passed.\n", ran)
		}
	} else {
		if len(os.Args) >= 2 {
			L := goal.NewGoalLuaContext("goal")
			fname := os.Args[1]
			success := goal.LuaDoFile(L, fname)
			if !success {
				fmt.Printf("Error: Error when running "+ fname +".\n")
			}
		} else {
			fmt.Printf("Error: Must either pass --tests, or file to run.\n")
		}
	}
}
