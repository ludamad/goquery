package goal

import (
	"bytes"
	"fmt"
	"log"
)

type TupleSchema struct {
	Id         int
	Name       string
	Fields     []string
	Keys       []string
	KeyIndices []int
	Store      map[string][]string
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
func (schema *TupleSchema) SaveTuple(tuple []string) {
	schema.Store[schema.keyStringFromTuple(tuple)] = tuple
}

func (schema *TupleSchema) LoadTuple(keys []string) []string {
	return schema.Store[schema.keyStringFromKeys(keys)]
}

func indexOf(strs []string, test string) int {
	for i, str := range strs {
		if str == test {
			return i
		}
	}

	log.Panicf("Could not find '%s' in %s", test, strs)
	return 0
}

func makeSchema(id int, name string, fields, keys []string) TupleSchema {
	keyIndices := []int{}
	for _, key := range keys {
		keyIndices = append(keyIndices, indexOf(fields, key))
	}
	return TupleSchema{id, name, fields, keys, keyIndices, map[string][]string{}}
}

type TupleStore struct {
	Schemas []TupleSchema
}

func MakeMemoryStore(schemas []TupleSchema) *TupleStore {
	return &TupleStore{schemas}
}

func (s *TupleStore) DefineTuple(name string, fields, keys []string) int {
	s.Schemas = append(s.Schemas, makeSchema(len(s.Schemas), name, fields, keys))
	return len(s.Schemas) - 1
}

func (s *TupleStore) SaveTuple(tupleKind int, tuple []string) {
	s.Schemas[tupleKind].SaveTuple(tuple)
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

func (s *TupleStore) PrintStore() {
	for _, schema := range s.Schemas {
		fmt.Printf("Schema %s:\n", schema.Name)
		for k, v := range schema.Store {
			fmt.Printf("%s => %s\n", k, v)
		}
	}
}
