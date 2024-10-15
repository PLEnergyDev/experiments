public class divisionloop {
    public static double divisionLoop(int M) {
        double sum = 0.0;
        int n = 0;
        while (sum < M) {
            n++;
            sum += 1.0 / n;
        }
        return n;
    }

    public static void main(String[] args) {
        int M = Integer.parseInt(args[0]);
        for (int i = 0; i < 10; i++) {
            double result = divisionLoop(M);
            System.out.printf("%f%n", result);
        }
    }
}
