///[INCLUDES]
package JavaIPC;

public class Main {
    public static void main(String[] args) throws Exception {
        if(args.length < 1) {
            System.err.println("usage: [socket]");
            System.exit(1);
        }
        var pipe = args[0];
        int LoopIterations = 1;
        FPipe p = new FPipe(pipe);
        Cmd c = Cmd.Unkown;
        try {
            p.WriteCmd(Cmd.Ready);
            do {
                p.WriteCmd(Cmd.Ready);
                p.ExpectCmd(Cmd.Go);
                for (int i = 0; i < LoopIterations; i++) {
                    ///[BENCHMARK]
                }
                ///[RESULT]
                p.WriteCmd(Cmd.Done);
                c = p.ReadCmd();
            }
            while (c == Cmd.Ready);
            System.out.println("Java Done!");
        } catch(PipeCmdException e) {
            System.err.println("An error occurred read: " + c);
        } catch(Exception e){
            p.WriteCmd(Cmd.Error);
        } finally {
            p.close();
        }
    }
}
