PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
LIBDIR := $(PREFIX)/lib
INCLUDEDIR := $(PREFIX)/include

USER := $(shell whoami)

# Rapl Interface Library
RAPL_DIR := rapl-interface
RAPL_LIB_NAME := librapl_interface.so
RAPL_SO := $(RAPL_DIR)/target/release/$(RAPL_LIB_NAME)

# Rapl Interface Header
HEADER_NAME :=rapl-interface.h

# Energy Script
ENERGY_MAIN := main.sh
ENERGY_SCRIPTS_DIR := scripts
ENERGY_APP_NAME := energy

all: $(RAPL_SO)

$(RAPL_SO):
	cargo build --release --manifest-path $(RAPL_DIR)/Cargo.toml

install: $(RAPL_SO) $(ENERGY_MAIN)
	install -d $(BINDIR) $(LIBDIR)/$(ENERGY_APP_NAME) $(INCLUDEDIR)
	install -o $(USER) -g $(USER) $(ENERGY_MAIN) $(BINDIR)/$(ENERGY_APP_NAME)

	install -o $(USER) -g $(USER) $(ENERGY_SCRIPTS_DIR)/* $(LIBDIR)/$(ENERGY_APP_NAME)/
	install -o $(USER) -g $(USER) $(RAPL_SO) $(LIBDIR)/

	install -o $(USER) -g $(USER) -m 644 $(HEADER_NAME) $(INCLUDEDIR)/

	ldconfig # Refresh linker cache

uninstall:
	rm -f $(BINDIR)/$(ENERGY_APP_NAME)

	rm -rf $(LIBDIR)/$(ENERGY_APP_NAME)
	rm -f $(LIBDIR)/$(RAPL_LIB_NAME)

	rm -f $(INCLUDEDIR)/$(HEADER_NAME)

	ldconfig # Refresh linker cache

clean:
	cargo clean --manifest-path $(RAPL_DIR)/Cargo.toml

.PHONY: all install uninstall clean
