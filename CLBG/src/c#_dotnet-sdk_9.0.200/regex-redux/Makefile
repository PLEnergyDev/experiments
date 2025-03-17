include ../Makefile

NIX_PKGS += pcre2

define run_nix
	$(NIX_SHELL) \
	'cd "$(THIS_DIR)" && PCRE2_PATH=$$(find /nix/store -path "*/lib/libpcre2-8.so" | head -n 1 | xargs dirname) && \
	env DOTNET_ROOT=$$(dirname $$(readlink -f $$(which $(CC)))) \
	LD_LIBRARY_PATH=$$PCRE2_PATH:$$LD_LIBRARY_PATH \
	$(1)'
endef

INPUT = < regexredux-input5000000.txt
