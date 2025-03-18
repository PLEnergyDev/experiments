THIS_DIR = $(shell pwd)

NIX_PKGS = gcc
NIX_COMMIT = https://github.com/NixOS/nixpkgs/archive/52e3095f6d812b91b22fb7ad0bfc1ab416453634.tar.gz
NIX_SHELL = nix-shell -p $(NIX_PKGS) -I nixpkgs=$(NIX_COMMIT) --run

CC = g++

RAPL_FLAGS = -lrapl_interface -I/usr/local/include -L/usr/local/lib
OPT_FLAGS = -pipe -O3 -march=native -fomit-frame-pointer
LIB_FLAGS =
CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS) $(RAPL_FLAGS)

TARGET = main
SRC = $(TARGET).cpp

define run_nix
	$(NIX_SHELL) \
	'cd "$(THIS_DIR)" && $(1)'
endef

all: $(TARGET)

$(TARGET): $(SRC)
	$(call run_nix, $(CC) $(SRC) -o $(TARGET) $(CFLAGS))

mem: $(TARGET)
	$(call run_nix, time -v ./$(TARGET) $(INPUT))

measure: $(TARGET)
	$(call run_nix, ./$(TARGET) $(INPUT))

valgrind: $(TARGET)
	$(call run_nix, valgrind --tool=massif --stacks=yes ./$(TARGET) $(INPUT))

clean:
	rm -f $(TARGET)

.PHONY: all run mem measure clean valgrind
.SILENT:
