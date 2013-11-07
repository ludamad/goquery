package goal

import (
	"bytes"
	"fmt"
	"database/sql"
)

type fieldType int
const (
	FIELD_TYPE_STRING fieldType = iota
	FIELD_TYPE_INT
)

type field struct {
	Name string
	Type fieldType
}

type TupleSchema struct {
	Id         int
	Name       string
	Fields     []field
	Keys       []string
	KeyIndices []int
	DBSchema   *DatabaseSchema
}

func (schema *TupleSchema) keyStringFromTuple(tuple []string) string {
	buf := bytes.NewBufferString("")
	for _, index := range schema.KeyIndices {
		buf.WriteString(tuple[index])
		buf.WriteRune(';')
	}
	return buf.String()
}

func (schema *TupleSchema) keyStringFromKeys(keys []string) string {
	buf := bytes.NewBufferString("")
	for _, key := range keys {
		buf.WriteString(key)
		buf.WriteRune(';')
	}
	return buf.String()
}

func (schema *TupleSchema) FieldLength() int { return len(schema.Fields) }
func (schema *TupleSchema) KeyLength() int   { return len(schema.Keys) }
func (schema *TupleSchema) SaveTuple(db *sql.DB, tuple []interface{}) {
	if db == nil {
		panic("A database connection was not provided! Provide a 'Database' argument to 'Analyze'.")
	}
	schema.DBSchema.Insert(db, tuple)
}

func (schema *TupleSchema) LoadTuple(keys []string) []string {
	panic("Dummied out!")
}

func indexOf(fields []field, test string) int {
	for i, f := range fields {
		if f.Name == test {
			return i
		}
	}

	panic("Could not find '" + test + "' in " + fmt.Sprint(fields))
	return 0
}

func makeSchema(id int, name string, fields []field, keys []string, schema *DatabaseSchema) TupleSchema {
	keyIndices := []int{}
	for _, key := range keys {
		keyIndices = append(keyIndices, indexOf(fields, key))
	}
	return TupleSchema{id, name, fields, keys, keyIndices, schema}
}

type TupleStore struct {
	Schemas []TupleSchema
}

func MakeMemoryStore(schemas []TupleSchema) *TupleStore {
	return &TupleStore{schemas}
}

func (s *TupleStore) DefineTuple(name string, fieldNames, keys []string) int {
	// TODO: All types are strings for now:
	fields := []field{}
	for _, fname := range fieldNames {
		fields = append(fields, field {fname, FIELD_TYPE_STRING})
	} 
	dbSchema := makeDatabaseSchema(name, fields, keys)
	s.Schemas = append(s.Schemas, makeSchema(len(s.Schemas), name, fields, keys, dbSchema))
	return len(s.Schemas) - 1
}

func (s *TupleStore) SaveTuple(db *sql.DB, tupleKind int, tuple []interface{}) {
	s.Schemas[tupleKind].SaveTuple(db, tuple)
}

func (s *TupleStore) FlushBuffers() {
	for _, schema := range s.Schemas {
		schema.DBSchema.Flush()
	}
}

func (s *TupleStore) SchemaFromName(name string) *TupleSchema {
	for _, schema := range s.Schemas {
		if schema.Name == name {
			return &schema
		}
	}
	panic("No schema by name " + name + "!")
}

func (s *TupleStore) LoadTuple(tupleKind int, keys []string) []string {
	t := s.Schemas[tupleKind].LoadTuple(keys)
	return t
}
