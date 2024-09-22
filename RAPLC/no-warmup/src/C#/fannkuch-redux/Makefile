compile:
	cp fannkuchredux.csharpcore-4.csharpcore Program.cs
	dotnet build -c Release

measure:
	sudo modprobe msr
	sudo ../../RAPL/main "dotnet ./bin/Release/net8.0/tmp.dll 12" CSharp fannkuch-redux

run:
	dotnet ./bin/Release/net8.0/tmp.dll 12

mem:
	time -v  dotnet ./bin/Release/net8.0/tmp.dll 12

valgrind:
	valgrind --tool=massif --stacks=yes  dotnet ./bin/Release/net8.0/tmp.dll 12
