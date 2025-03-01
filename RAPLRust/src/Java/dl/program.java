public class program {
    static {
        System.loadLibrary("rapl_interface");
    }
    public native boolean start_rapl();
    public native void stop_rapl();

    static void run_benchmark(int m) {
        double sum = 0.0;
        int n = 0;
        while (sum < m) {
            n++;
            sum += 1.0 / n;
        }
        System.out.printf("%d\n", n);
    }

    public static void main(String[] args) {
        int m = Integer.parseInt(args[0]);
        program rapl = new program();

        while (rapl.start_rapl()) {
            run_benchmark(m);
            rapl.stop_rapl();
        }
    }
}
