compile:
	cp pidigits.csharpcore-3.csharpcore Program.cs
	dotnet build -c Release

measure:
	sudo modprobe msr
	sudo ../../RAPL/main "dotnet ./bin/Release/net8.0/tmp.dll 10000" CSharp pidigits

run:
	dotnet ./bin/Release/net8.0/tmp.dll 10000

mem:
	time -v  dotnet ./bin/Release/net8.0/tmp.dll 10000

valgrind:
	valgrind --tool=massif --stacks=yes  dotnet ./bin/Release/net8.0/tmp.dll 10000
