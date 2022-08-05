.cask: Cask
	cask install

ELC := $(patsubst %.el,%.elc,$(wildcard *.el))

$(ELC): .cask $(wildcard *.el)
	cask build

compile: $(ELC)

.PHONY: compile
