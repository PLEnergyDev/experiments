using SocketComm;

namespace CsharpIPC;

public class Program {
    public static void Main(string[] args) {
        if (args.Length < 1) {
            Console.Error.WriteLine("usage: [socket]");
            return;
        }

        var path = args[0];
        var LoopIterations = 1;
        var pipe = new FPipe(path);
        pipe.Connect();
        pipe.WriteCmd(Cmd.Ready);

        Cmd c;
        do {
            pipe.WriteCmd(Cmd.Ready);
            pipe.ExpectCmd(Cmd.Go);
            for (int i = 0; i < LoopIterations; i++) {
                ///[BENCHMARK]
            }
            ///[RESULT]
            pipe.WriteCmd(Cmd.Done);
            c = pipe.ReadCmd();
        } while(c == Cmd.Ready);
        pipe.Dispose();
    }
}