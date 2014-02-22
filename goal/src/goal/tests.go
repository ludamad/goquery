package goal

import (
	"fmt"
	"github.com/stevedonovan/luar"
	"io/ioutil"
	"regexp"
)

func RunTests(dir string, onlyRun int) (int,int) {
	io, err := ioutil.ReadDir(dir)
	if err != nil {
		fmt.Print(err)
		return 1,1
	}

	failList := []string{}
	failures, total, n := 0, 0, 0
	for _, file := range io {
		fname := file.Name()
		if matched, err := regexp.MatchString("\\d.*\\.lua$", fname) ; !matched || err != nil {
			continue
		}
		n++;
		if onlyRun != -1 && onlyRun != n {
			continue;
		}
		total++
		L := NewGoalLuaContext("goal")
		// Note: the Goal lua context is strict, so variables must exist before we operate on them:
		L.NewTable()
		L.SetGlobal("goaltest")
		luar.Register(L, "goaltest", luar.Map {
			"Filename":      fname,
			"DirectoryName": dir,
		})
		colorPrintf("0;1", "Test '%s' is running... \n", fname)
		success := LuaDoFile(L, dir+"/"+fname)
		if success {
			colorPrintf("0;1", "Test '%s' succeeded!\n", fname)
		} else {
			colorPrintf("31;1", "Test '%s' FAILED ... \n", fname)
			failList = append(failList, fname)
			failures++
		}
	}
	if failures > 0 {
		colorPrintf("31;1", "Failures: ")
		for _, failString := range failList {
			colorPrintf("31", "%s\t", failString)
		}
		fmt.Printf("\n")
	}
	return failures,total
}
