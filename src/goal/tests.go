package goal

import (
	"fmt"
	"github.com/stevedonovan/luar"
	"io/ioutil"
	"strings"
)

func RunTests(dir string, onlyRun int) (int,int) {
	io, err := ioutil.ReadDir(dir)
	if err != nil {
		fmt.Print(err)
		return 1,1
	}

	failures, total, n := 0, 0, 0
	for _, file := range io {
		fname := file.Name()
		if fname[0] != '0' || strings.Index(fname, ".lua") != len(fname)-4 || fname == "prelude.lua" {
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
			failures++
		}
	}
	return failures,total
}
