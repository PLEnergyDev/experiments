compile:
	cp threadring.csharpcore Program.cs
	dotnet build -c Release

measure:
	sudo modprobe msr
	sudo ../../RAPL/main "dotnet ./bin/Release/net8.0/tmp.dll 50000000" CSharp thread-ring

run:
	dotnet ./bin/Release/net8.0/tmp.dll 50000000

mem:
	time -v  dotnet ./bin/Release/net8.0/tmp.dll 50000000

valgrind:
	valgrind --tool=massif --stacks=yes  dotnet ./bin/Release/net8.0/tmp.dll 50000000
