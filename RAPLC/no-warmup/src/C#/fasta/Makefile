compile:
	cp fasta.csharpcore Program.cs
	dotnet build -c Release

measure:
	sudo modprobe msr
	sudo ../../RAPL/main "dotnet ./bin/Release/net8.0/tmp.dll 25000000" CSharp fasta

run:
	dotnet ./bin/Release/net8.0/tmp.dll 25000000

mem:
	time -v  dotnet ./bin/Release/net8.0/tmp.dll 25000000

valgrind:
	valgrind --tool=massif --stacks=yes  dotnet ./bin/Release/net8.0/tmp.dll 25000000
