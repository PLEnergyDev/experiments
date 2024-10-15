public class polynomialevaluation {

    public static double[] initCs(int n) {
        double[] cs = new double[n];
        for (int i = 0; i < n; i++) {
            cs[i] = 1.1 * i;
            if (i % 3 == 0) {
                cs[i] *= -1;
            }
        }
        return cs;
    }

    public static double polynomialEvaluation(int n) {
        double[] cs = initCs(n);
        double res = 0.0;

        for (int i = 0; i < n; i++) {
            res = cs[i] + 5.0 * res;
        }

        return res;
    }

    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("Usage: java polynomialevaluation <n>");
            return;
        }

        int n = Integer.parseInt(args[0]);
        for (int i = 0; i < 1000; i++) {
            double result = polynomialEvaluation(n);
            System.out.printf("%f%n", result);
        }
    }
}
