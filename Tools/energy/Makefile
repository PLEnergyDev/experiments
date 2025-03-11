PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
LIBDIR := $(PREFIX)/lib
INCLUDEDIR := $(PREFIX)/include

USER := $(shell whoami)

# Rapl Interface Library
RAPL_DIR := rapl-interface
RAPL_LIB_NAME := librapl_interface.so
RAPL_SO := $(RAPL_DIR)/target/release/$(RAPL_LIB_NAME)

# Python Scripts
PYTHON_SCRIPTS_DIR := python-scripts

# Rapl Interface Header
HEADER_NAME := rapl-interface.h

# Energy Script
ENERGY_MAIN := main.sh
ENERGY_SETUPS_DIR := setups
ENERGY_COMMANDS_DIR := commands
ENERGY_TOOL_NAME := energy


all: $(RAPL_SO)

$(RAPL_SO):
	cargo build --release --manifest-path $(RAPL_DIR)/Cargo.toml

install: $(RAPL_SO) $(ENERGY_MAIN)
	install -d $(BINDIR) $(LIBDIR)/$(ENERGY_APP_NAME) $(INCLUDEDIR)
	install -d $(LIBDIR)/$(ENERGY_TOOL_NAME)/$(ENERGY_COMMANDS_DIR)
	install -d $(LIBDIR)/$(ENERGY_TOOL_NAME)/$(ENERGY_SETUPS_DIR)
	install -d $(LIBDIR)/$(ENERGY_TOOL_NAME)/$(PYTHON_SCRIPTS_DIR)

	install $(ENERGY_MAIN) $(BINDIR)/$(ENERGY_TOOL_NAME)

	install $(ENERGY_COMMANDS_DIR)/* $(LIBDIR)/$(ENERGY_TOOL_NAME)/$(ENERGY_COMMANDS_DIR)/
	install $(ENERGY_SETUPS_DIR)/* $(LIBDIR)/$(ENERGY_TOOL_NAME)/$(ENERGY_SETUPS_DIR)/
	install $(PYTHON_SCRIPTS_DIR)/* $(LIBDIR)/$(ENERGY_TOOL_NAME)/$(PYTHON_SCRIPTS_DIR)/

	install $(RAPL_SO) $(LIBDIR)/
	install -m 644  $(HEADER_NAME) $(INCLUDEDIR)/

	ldconfig # Refresh linker cache

uninstall:
	rm -f $(BINDIR)/$(ENERGY_TOOL_NAME)

	rm -rf $(LIBDIR)/$(ENERGY_TOOL_NAME)
	rm -f $(LIBDIR)/$(RAPL_LIB_NAME)

	rm -f $(INCLUDEDIR)/$(HEADER_NAME)

	ldconfig # Refresh linker cache

clean:
	cargo clean --manifest-path $(RAPL_DIR)/Cargo.toml

.PHONY: all install uninstall clean
