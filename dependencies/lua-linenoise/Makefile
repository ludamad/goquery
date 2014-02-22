OS=$(shell uname)

OBJECTS=linenoise.o

ifeq ($(LIBLINENOISE),)
  OBJECTS+=linenoiselib.o
else
  OPT_LIB=$(LIBLINENOISE)
endif

ifeq ($(OS),Darwin)
linenoise.dylib: $(OBJECTS)
	gcc -o $@ -bundle -undefined dynamic_lookup $^ $(OPT_LIB)
else
CFLAGS=-fPIC -I"../LuaJIT-2.0.2/src"
linenoise.so: $(OBJECTS)
	gcc -o $@ -shared $^ $(OPT_LIB)
endif

clean:
	rm -f *.o *.so *.dylib
