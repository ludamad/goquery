package goal

import (
	"bytes"
	"log"
)

type TupleSchema struct {
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

func MakeSchema(fields, keys []string) TupleSchema {
	keyIndices := []int{}
	for _, key := range keys {
		keyIndices = append(keyIndices, indexOf(fields, key))
	}
	return TupleSchema{fields, keys, keyIndices, map[string][]string{}}
}

type TupleStore struct {
	Schemas []TupleSchema
}

func MakeMemoryStore(schemas []TupleSchema) *TupleStore {
	return &TupleStore{schemas}
}

func (s *TupleStore) DefineTuple(fields, keys []string) int {
	s.Schemas = append(s.Schemas, MakeSchema(fields, keys))
	return len(s.Schemas) - 1
}

func (s *TupleStore) SaveTuple(tupleKind int, tuple []string) {
	s.Schemas[tupleKind].SaveTuple(tuple)
}

func (s *TupleStore) LoadTuple(tupleKind int, keys []string) []string {
	t := s.Schemas[tupleKind].LoadTuple(keys)
	return t
}
