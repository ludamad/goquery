package main

import (
	"./goquery"

	_ "github.com/mattn/go-sqlite3"

	"flag"
)


func main() {
	flag.Parse()

	// Parse command line files:
	context := goquery.NewContext()
	context.Parse(flag.Args())
//	context.DebugPrint()

	// Dump to DB:
	db := goquery.DBInitialize("sqlite3", "./hello-world.db", true /*Delete previous*/)
	context.DatabaseInsert(db, goquery.Configuration{})
	db.Close()
}
