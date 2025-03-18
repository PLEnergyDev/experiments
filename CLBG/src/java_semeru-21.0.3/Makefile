THIS_DIR = $(shell pwd)

NIX_PKGS = semeru-bin
NIX_COMMIT = https://github.com/NixOS/nixpkgs/archive/52e3095f6d812b91b22fb7ad0bfc1ab416453634.tar.gz
NIX_SHELL = nix-shell -p $(NIX_PKGS) -I nixpkgs=$(NIX_COMMIT) --run

JAVAC = javac
JAVA = java

CFLAGS = --enable-preview --release 21 -nowarn
RFLAGS = --enable-preview --enable-native-access=ALL-UNNAMED

CLASS = program
SRC = $(CLASS).java

define run_nix
	$(NIX_SHELL) \
	'cd "$(THIS_DIR)" && $(1)'
endef

all: $(CLASS)

$(CLASS): $(SRC)
	$(call run_nix, $(JAVAC) $(CFLAGS) $(SRC))

mem: $(CLASS)
	$(call run_nix, time -v $(JAVA) $(RFLAGS) $(CLASS) $(INPUT))

measure: $(CLASS)
	$(call run_nix, $(JAVA) $(RFLAGS) $(CLASS) $(INPUT))

valgrind:
	$(call run_nix, valgrind --tool=massif --stacks=yes $(JAVA) $(RFLAGS) $(CLASS) $(INPUT))

clean:
	rm -f *.class

.PHONY: all run mem measure clean valgrind
.SILENT:
