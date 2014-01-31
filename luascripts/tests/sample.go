package main

func intFunc() int {
	return 0
}

func stringFunc() string {
	return ""
}

type Foo struct {
	field int
}


func (f *Foo) IntMethod() int {
	return 0
}

func (f *Foo) StringMethod() string {
	return ""
}

func main() {}