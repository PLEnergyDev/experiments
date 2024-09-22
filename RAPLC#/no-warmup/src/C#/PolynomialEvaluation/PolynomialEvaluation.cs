namespace CsharpIPC;

public class PolynomialEvaluation {
	static double[] InitCS(int n) {
		double[] cs = new double[n];
	    for (int i = 0; i < n; i++) {
	        cs[i] = 1.1 * i;
	        if (i % 3 == 0) {
	            cs[i] *= -1;
	        }
	    }

	    return cs;
	}

	public static double RunPolynomialEvaluation(int n) {
		double[] cs = InitCS(n);
		double res = 0.0;

	    for (int i = 0; i < n; i++) {
	        res = cs[i] + 5.0 * res;
	    }

	    return res;
	}
}