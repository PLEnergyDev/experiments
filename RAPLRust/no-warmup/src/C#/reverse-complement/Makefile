compile:
	cp revcomp.csharpcore-2.csharpcore Program.cs
	dotnet build -c Release

measure:
	sudo modprobe msr
	sudo ../../RAPL/target/release/RAPL "dotnet ./bin/Release/net8.0/tmp.dll 0 < ../../revcomp-input25000000.txt"

run:
	dotnet ./bin/Release/net8.0/tmp.dll 0 < ../../revcomp-input25000000.txt

mem:
	time -v  dotnet ./bin/Release/net8.0/tmp.dll 0 < ../../revcomp-input25000000.txt

valgrind:
	valgrind --tool=massif --stacks=yes   dotnet ./bin/Release/net8.0/tmp.dll 0 < ../../revcomp-input25000000.txt
