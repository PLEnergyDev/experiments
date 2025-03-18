NAME := energy

PREFIX := /usr/local
BIN_DIR := $(PREFIX)/bin
LIB_DIR := $(PREFIX)/lib/$(NAME)
INCLUDE_DIR := $(PREFIX)/include/$(NAME)
SHARE_DIR := $(PREFIX)/share/$(NAME)
CONFIG_DIR := $(PREFIX)/etc/$(NAME)

# Rapl Interface Library
RAPL_DIR := rapl-interface
RAPL_SO := $(RAPL_DIR)/target/release/librapl_interface.so
RAPL_HEADER := $(RAPL_DIR)/rapl-interface.h

COMMANDS_DIR := $(LIB_DIR)/commands
SCRIPTS_DIR := $(LIB_DIR)/scripts
SETUPS_DIR := $(LIB_DIR)/setups

all: $(RAPL_SO)

$(RAPL_SO):
	cargo build --release --manifest-path $(RAPL_DIR)/Cargo.toml

install: $(RAPL_SO) main.sh
	install -d -m 755 $(LIB_DIR) $(INCLUDE_DIR) $(SHARE_DIR) $(CONFIG_DIR)
	install -d -m 755 $(SETUPS_DIR) $(COMMANDS_DIR) $(SCRIPTS_DIR)

	sed -e "s|{{LIB_DIR}}|$(LIB_DIR)|g" \
	    -e "s|{{NAME}}|$(NAME)|g" \
	    -e "s|{{COMMANDS_DIR}}|$(COMMANDS_DIR)|g" \
	    -e "s|{{SCRIPTS_DIR}}|$(SCRIPTS_DIR)|g" \
	    -e "s|{{SETUPS_DIR}}|$(SETUPS_DIR)|g" \
	    main.sh > $(LIB_DIR)/$(NAME)
	chmod 755 $(LIB_DIR)/$(NAME)

	install -m 644 commands/* $(COMMANDS_DIR)
	install -m 644 scripts/* $(SCRIPTS_DIR)
	install -m 644 setups/* $(SETUPS_DIR)

	install -m 755 $(RAPL_SO) $(LIB_DIR)
	install -m 644 $(RAPL_HEADER) $(INCLUDE_DIR)

	ln -sf $(LIB_DIR)/$(NAME) $(BIN_DIR)/$(NAME)
	ln -sf $(LIB_DIR)/librapl_interface.so $(PREFIX)/lib/librapl_interface.so
	ln -sf $(INCLUDE_DIR)/rapl-interface.h $(PREFIX)/include/rapl-interface.h

	ldconfig # Refresh linker cache

uninstall:
	rm -f $(BIN_DIR)/$(NAME)
	rm -f $(PREFIX)/lib/librapl_interface.so
	rm -f $(PREFIX)/include/rapl-interface.h

	rm -rf $(LIB_DIR) $(INCLUDE_DIR) $(SHARE_DIR) $(CONFIG_DIR)

	ldconfig # Refresh linker cache

clean:
	cargo clean --manifest-path $(RAPL_DIR)/Cargo.toml

.PHONY: all install uninstall clean
.SILENT: