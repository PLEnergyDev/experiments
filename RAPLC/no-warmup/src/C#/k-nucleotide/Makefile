compile:
	cp knucleotide.csharpcore-6.csharpcore Program.cs
	dotnet build -c Release

measure:
	sudo modprobe msr
	sudo ../../RAPL/main "dotnet ./bin/Release/net8.0/tmp.dll 0 < ../../knucleotide-input25000000.txt" CSharp k-nucleotide

run:
	dotnet ./bin/Release/net8.0/tmp.dll 0 < ../../knucleotide-input25000000.txt

mem:
	time -v dotnet ./bin/Release/net8.0/tmp.dll 0 < ../../knucleotide-input25000000.txt

valgrind:
	valgrind --tool=massif --stacks=yes dotnet ./bin/Release/net8.0/tmp.dll 0 < ../../knucleotide-input25000000.txt
