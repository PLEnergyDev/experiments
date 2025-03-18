THIS_DIR = $(shell pwd)

NIX_PKGS = cargo
NIX_COMMIT = https://github.com/NixOS/nixpkgs/archive/52e3095f6d812b91b22fb7ad0bfc1ab416453634.tar.gz
NIX_SHELL = nix-shell -p $(NIX_PKGS) -I nixpkgs=$(NIX_COMMIT) --run

CC=cargo

CFLAGS=--release

TARGET=target/release/main
SRC=src/main.rs

define run_nix
	$(NIX_SHELL) \
	'cd "$(THIS_DIR)" && $(1)'
endef

all: $(TARGET)

$(TARGET): $(SRC)
	$(call run_nix, $(CC) build $(CFLAGS))

run: $(TARGET)
	$(call run_nix, ./$(TARGET) $(INPUT))

mem: $(TARGET)
	$(call run_nix, time -v ./$(TARGET) $(INPUT))

measure: $(TARGET)
	$(call run_nix, ./$(TARGET) $(INPUT))

valgrind: $(TARGET)
	$(call run_nix, valgrind --tool=massif --stacks=yes ./$(TARGET) $(INPUT))

clean:
	$(CC) clean

.PHONY: all run mem measure clean valgrind
.SILENT:
