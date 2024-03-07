namespace CsharpIPC;

public class DivisionLoop {
    public static int RunDivisionLoop(int M) {
        double sum = 0.0;
        int n = 0;
        while (sum < M) {
            n++;
            sum += 1.0 / n;
        }
        return n;
    }
}