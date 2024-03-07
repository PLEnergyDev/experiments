public class DivisionLoop {
    public static int DivisionLoop() {
        int M = 22;
        double sum = 0.0;
        int n = 0;
        while (sum < M) {
            n++;
            sum += 1.0 / n;
        }
        return n;
    }

    public static void main(String[] args) {
        DivisionLoop();
    }
}
