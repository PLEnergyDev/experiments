CC=javac
CFLAGS=--enable-preview --release 21 -d . -cp .:/usr/local/src/java-libs/fastutil-7.0.12.jar
RFLAGS=--enable-preview -cp .:/usr/local/src/java-libs/fastutil-7.0.12.jar

TARGET=knucleotide
SRC=knucleotide.java

COUNT=20
INPUT=

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC)

run: $(TARGET)
	java $(RFLAGS) $(TARGET) 1 < ../../knucleotide-input25000000.txt

measure: $(TARGET)
	modprobe msr
	java $(RFLAGS) $(TARGET) $(COUNT) < ../../knucleotide-input25000000.txt

mem: $(TARGET)
	time -v java $(RFLAGS) $(TARGET) 1 < ../../knucleotide-input25000000.txt

clean:
	rm -f *.class

.PHONY: all clean
