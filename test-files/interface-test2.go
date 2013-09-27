package test2

type I1 interface {
	Test(I1)A
}

type I2 interface {
	Test(I1)A
}

type C struct {}

type A func(C) C

func (_ A) Test(I1)A {}
