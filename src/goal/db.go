package goal

import (
	"database/sql"
	"log"
	"os"
	"strings"
	"fmt"
	"regexp"
)

func dbInitialize(driver string, filename string, deletePrevious bool) *sql.DB{
	if deletePrevious {
		os.Remove(filename)
	}
	db, err := sql.Open(driver, filename)
	if err != nil {
		log.Fatal(err)
	}
	return db
}

type insertBatcher struct {
	insertCount int
	insertTransaction *sql.Tx
	insertStatement *sql.Stmt
}

func (b *insertBatcher) Insert(fieldData []interface{}) {
	b.insertStatement.Exec(fieldData...)
}

func (b *insertBatcher) Close() {
	b.insertStatement.Close()
	b.insertTransaction.Commit()
}

func makeInsertBatcher(db *sql.DB, name string, fields []field) *insertBatcher {
	// Assumes at least one arg in 'args':
	marks := "?" + strings.Repeat(", ?", len(fields)-1)
	sql := "INSERT INTO " + name + " values(" + marks + ")"
	tx, err := db.Begin()
	if err != nil {
		panic(err)
	}

	stmt, err := tx.Prepare(sql)
	if err != nil {
		panic(err)
	}
	return &insertBatcher{0, tx, stmt}
}

type DatabaseSchema struct {
	Name       string
	Fields     []field
	Keys []string
	batcher	*insertBatcher
}

func makeDatabaseSchema(name string, fields []field, keys []string) *DatabaseSchema {
	return &DatabaseSchema {name, fields, keys, nil}
}

func (ds *DatabaseSchema) Flush() {
	if ds.batcher != nil {
		ds.batcher.Close() ; ds.batcher = nil
	}
}

func sqlCheckName(name string) {
	if match,_ := regexp.MatchString(name, "^[\\w_]+$") ; match {
		panic("Sql-exposed names must consist only of alphanumeric characters, or _! Bad name: " + name)
	}
}

func (ds *DatabaseSchema) CreateTable(db *sql.DB) {
	sqlCheckName(ds.Name) // Be a little safer about string interpolation
	fieldSchema := []string{}
	for _, f := range ds.Fields {
		sqlCheckName(f.Name)
		if f.Type == FIELD_TYPE_STRING {
			fieldSchema = append(fieldSchema, f.Name + " TEXT")
		} else {
			panic("Unexpected field type!")
		}
	}
	sql := fmt.Sprintf("CREATE TABLE %s(%s, PRIMARY KEY (%s))", ds.Name, strings.Join(fieldSchema, ","), strings.Join(ds.Keys, ","))
	_, err := db.Exec(sql)
	if err != nil {
		panic(err)
	}
}

func (ds *DatabaseSchema) Insert(db *sql.DB, fieldData []interface{}) {
	if ds.batcher == nil {
		ds.CreateTable(db)
		ds.batcher = makeInsertBatcher(db, ds.Name, ds.Fields)
	}
	ds.batcher.Insert(fieldData)
}