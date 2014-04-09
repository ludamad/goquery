package goal

import (
	"database/sql"
	"fmt"
	_ "github.com/lib/pq"
	_ "github.com/mattn/go-sqlite3"
	"os"
	"regexp"
	"strings"
)

type DatabaseBuffer struct {
	stmt string
	data [][]interface{}
}

type DatabaseContext struct {
	DB            *sql.DB
	insertBuffers map[int]*DatabaseBuffer
}

func (context *DatabaseContext) commit(buff *DatabaseBuffer, insertTransaction *sql.Tx) {
	stmt, err := insertTransaction.Prepare(buff.stmt)
	if err != nil {
		panic(err)
	}
	for _, dat := range buff.data {
		stmt.Exec(dat...)
	}
	stmt.Close()
}

var DUMMY_DB bool = (os.Getenv("DUMMY") != "")

func (context *DatabaseContext) Commit() {
	if context.DB == nil {
		return
	}
	if DUMMY_DB {
		context.insertBuffers = map[int]*DatabaseBuffer{}
		return
	}
	tx, err := context.DB.Begin()
	if err != nil {
		panic(err)
	}
	for _, buffer := range context.insertBuffers {
		context.commit(buffer, tx)
	}
	context.insertBuffers = map[int]*DatabaseBuffer{}
	tx.Commit()
}

func (context *DatabaseContext) makeDatabaseBuffer(name string, fields []field) *DatabaseBuffer {
	// Assumes at least one arg in 'args':
	marks := "?" + strings.Repeat(", ?", len(fields)-1)
	sql := "INSERT INTO " + name + " values(" + marks + ")"
	return &DatabaseBuffer{sql, [][]interface{}{}}
}

func (context *DatabaseContext) GetInsertBuffer(ds *DataSchema) *DatabaseBuffer {
	buffer := context.insertBuffers[ds.Id]
	if buffer == nil {
		buffer = context.makeDatabaseBuffer(ds.Name, ds.Fields)
		context.insertBuffers[ds.Id] = buffer
	}
	return buffer
}

// Database connection and insertion functions:
func newDBConnection(dbKind string, filename string, deletePrevious bool) *sql.DB {
	if deletePrevious {
		os.Remove(filename)
	}
	db, err := sql.Open(dbKind, filename)
	if err != nil {
		panic(err)
	}
	return db
}

func (context *DatabaseContext) OpenConnection(dbKind string, filename string, deletePrevious bool) {
	if context.DB != nil {
		panic("Database connection already open!")
	}
	context.DB = newDBConnection(dbKind, filename, deletePrevious)
}
func (context *DatabaseContext) CloseConnection() {
	if context.DB != nil {
		context.Commit()
		context.DB.Close()
		context.DB = nil
	}
}

func (context *DataContext) DropAllData() {
	context.Commit()
	for _, s := range context.Schemas {
		sqlCheckName(s.Name)
		_, err := context.DB.Exec("drop table " + s.Name)
		if err != nil {
			panic(err)
		}
		s.CreateTable(context.DatabaseContext)
	}
}

// Global symbol context functions:
// Run a query. Return the column names, and the tuple results.
func (context *DatabaseContext) Query(query string, args ...interface{}) ([]string, [][]interface{}) {
	rows, err := context.DB.Query(query, args...)
	if err != nil {
		fmt.Printf("Error occurred in Query running this query\n %s", query)
		panic(err)
	}
	columns, _ := rows.Columns()
	results := [][]interface{}{}
	for rows.Next() {
		ifaceBoxes := []interface{}{}
		for i := 0; i < len(columns); i++ {
			ifaceBoxes = append(ifaceBoxes, new(interface{}))
		}
		err = rows.Scan(ifaceBoxes...)
		result := make([]interface{}, len(columns))
		for i := 0; i < len(columns); i++ {
			result[i] = *ifaceBoxes[i].(*interface{})
		}
		results = append(results, result)
	}
	err = rows.Err()
	if err != nil {
		panic(err)
	}
	return columns, results
}

func sqlCheckName(name string) {
	if match, _ := regexp.MatchString(name, "^[\\w_]+$"); match {
		panic("Sql-exposed names must consist only of alphanumeric characters, or _! Bad name: " + name)
	}
}

func (ds *DataSchema) CreateTable(context *DatabaseContext) {
	sqlCheckName(ds.Name) // Be a little safer about string interpolation
	fieldSchema := []string{}
	for _, f := range ds.Fields {
		sqlCheckName(f.Name)
		fieldSchema = append(fieldSchema, f.Name+" "+f.Type)
	}
	sql := fmt.Sprintf("CREATE TABLE %s(%s, PRIMARY KEY (%s))", ds.Name, strings.Join(fieldSchema, ","), strings.Join(ds.Keys, ","))
	//fmt.Print("SQL: ", sql, "\n")
	_, err := context.DB.Exec(sql)

	if err != nil {
		// fmt.Println(err) // Catch errors later, usually this means the table already exists, which is fine
	}
}

func (ds *DataSchema) Insert(context *DatabaseContext, fieldData []interface{}) {
	ctxt := context.GetInsertBuffer(ds)
	ctxt.data = append(ctxt.data, fieldData)
	if len(ctxt.data) > 1000 {
		context.Commit()
	}
}
