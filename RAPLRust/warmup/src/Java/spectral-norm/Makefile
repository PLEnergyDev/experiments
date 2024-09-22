CC=javac
CFLAGS=--enable-preview --release 21 -d .

TARGET=spectralnorm
SRC=spectralnorm.java

COUNT=20
INPUT=5500

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC)

run: $(TARGET)
	java --enable-preview $(TARGET) 1 $(INPUT)

measure: $(TARGET)
	modprobe msr
	java --enable-preview $(TARGET) $(COUNT) $(INPUT)

mem: $(TARGET)
	time -v java --enable-preview $(TARGET) 1 $(INPUT)

clean:
	rm -f *.class

.PHONY: all clean
