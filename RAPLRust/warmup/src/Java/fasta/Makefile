CC=javac
CFLAGS=--enable-preview --release 21 -d .

TARGET=fasta
SRC=fasta.java

COUNT=20
INPUT=25000000

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
