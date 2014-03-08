GOCMD=go
GOBUILD=$(GOCMD) build -p 8
GOCLEAN=$(GOCMD) clean
GODEP=$(GOCMD) test -i

PACKAGES = goal

BUILD_LIST = $(foreach int, $(PACKAGES), $(int)_build)
CLEAN_LIST = $(foreach int, $(PACKAGES), $(int)_clean)
IREF_LIST = $(foreach int, $(PACKAGES), $(int)_iref)

.PHONY: $(CLEAN_LIST) $(BUILD_LIST) $(IREF_LIST)

all: build
build: $(BUILD_LIST)
clean: $(CLEAN_LIST)
iref: $(IREF_LIST)

$(BUILD_LIST): %_build: %_iref
	$(GOBUILD) $(PACKAGES)
	$(GOCMD) build src/main.go
$(CLEAN_LIST): %_clean:
	$(GOCLEAN) $(PACKAGES)
$(IREF_LIST): %_iref:
	$(GODEP) $(PACKAGES)


#----------------------------------

.PHONY: sandbox

sandbox: astree

astree: src/sandbox/cmd/astree.go
	$(GOCMD) build src/sandbox/cmd/astree.go
