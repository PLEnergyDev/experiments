THIS_DIR = $(shell pwd)

NIX_PKGS = dotnet-sdk_9
NIX_COMMIT = https://github.com/NixOS/nixpkgs/archive/52e3095f6d812b91b22fb7ad0bfc1ab416453634.tar.gz
NIX_SHELL = nix-shell -p $(NIX_PKGS) -I nixpkgs=$(NIX_COMMIT) --run

CC = dotnet
CFLAGS = -c Release

TARGET = bin/Release/net9.0/program
SRC = Program.cs

define run_nix
	$(NIX_SHELL) \
	'cd "$(THIS_DIR)" && env DOTNET_ROOT=$$(dirname $$(readlink -f $$(which $(CC)))) $(1)'
endef

all: $(TARGET)

$(TARGET): $(SRC)
	$(call run_nix, $(CC) build $(CFLAGS))

mem: $(TARGET)
	$(call run_nix, time -v ./$(TARGET) $(INPUT))

measure: $(TARGET)
	$(call run_nix, ./$(TARGET) $(INPUT))

valgrind: $(TARGET)
	$(call run_nix, valgrind --tool=massif --stacks=yes ./$(TARGET) $(INPUT))

clean:
	$(call run_nix, $(CC) clean)
	rm -rf bin obj

.PHONY: all run mem measure clean valgrind
.SILENT:
