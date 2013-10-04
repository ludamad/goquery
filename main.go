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

	// Dump to DB:
	db := goquery.DBInitialize("sqlite3", "./hello-world.db" /*Delete previous*/, true)
	context.DatabaseInsert(db)
	db.Close()
}
