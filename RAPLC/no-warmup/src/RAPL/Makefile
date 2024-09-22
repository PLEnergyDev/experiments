CC=gcc
CFLAGS=-O2 -Wall -lm

TARGET=main
SRC=$(TARGET).c
OBJ=rapl.o

$(TARGET): $(SRC) $(OBJ)
	$(CC) $(SRC) $(OBJ) -o $(TARGET) $(CFLAGS)

$(OBJ): rapl.c rapl.h
	$(CC) -c rapl.c -o $(OBJ) $(CFLAGS)

clean:
	rm -f $(TARGET) $(OBJ)

.PHONY: all clean
