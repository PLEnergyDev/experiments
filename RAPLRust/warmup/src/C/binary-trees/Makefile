CC=gcc

OPT_FLAGS=-pipe -Wall -O3 -fomit-frame-pointer -march=ivybridge -fopenmp -I/usr/include/apr-1.0 -D_FILE_OFFSET_BITS=64
LIB_FLAGS=-lapr-1 -lgmp -lm -L$(RAPL_DIR)/target/release -lrapl_lib -Wl,-rpath=$(RAPL_DIR)/target/release

CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS)

TARGET=main
SRC=$(TARGET).c

RAPL_DIR=../../rapl-interface
RAPL=$(RAPL_DIR)/target/release/librapl_lib.so

COUNT=45
INPUT=21

$(RAPL):
	@echo "Building rapl-interface with cargo in release mode..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET) $(RAPL)
	./$(TARGET) 1 $(INPUT)

measure: $(TARGET) $(RAPL)
	./$(TARGET) $(COUNT) $(INPUT)

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) 1 $(INPUT)

valgrind: $(TARGET) $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) 1 $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind
