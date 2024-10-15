CC=g++

OPT_FLAGS=-pipe -O3 -fomit-frame-pointer -march=native -fopenmp -mfpmath=sse -msse3 -std=c++11
LIB_FLAGS=-L$(RAPL_DIR)/target/release -lrapl_lib -Wl,-rpath=$(RAPL_DIR)/target/release

CFLAGS=$(OPT_FLAGS) $(LIB_FLAGS)

TARGET=main
SRC=$(TARGET).cpp

RAPL_DIR=../../rapl-interface
RAPL=$(RAPL_DIR)/target/release/librapl_lib.so
COUNT=20
INPUT=80 80

$(RAPL):
	@echo "Building rapl-interface with cargo in release mode..."
	@cd $(RAPL_DIR) && cargo build --release

all: $(RAPL) $(TARGET)

$(TARGET): $(SRC) $(RAPL)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET) $(RAPL)
	./$(TARGET) 1 $(INPUT)

measure: $(TARGET) $(RAPL)
	modprobe msr
	./$(TARGET) $(COUNT) $(INPUT)

mem: $(TARGET) $(RAPL)
	time -v ./$(TARGET) 1 $(INPUT)

valgrind: $(RAPL)
	valgrind --tool=massif --stacks=yes ./$(TARGET) 1 $(INPUT)

clean:
	rm -f $(TARGET)

.PHONY: all clean run measure mem valgrind
