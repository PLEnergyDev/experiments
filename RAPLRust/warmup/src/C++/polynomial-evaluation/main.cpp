#include <iostream>
#include <vector>

extern "C" {
    void start_rapl();
    void stop_rapl();
}

std::vector<double> cs;
int n;

void initialize() {
    cs.resize(n);
    for (int i = 0; i < n; i++) {
        cs[i] = 1.1 * i;
        if (i % 3 == 0) {
            cs[i] *= -1;
        }
    }
}

double polynomial_evaluation() {
    double res = 0.0;
    for (int i = 0; i < n; i++) {
        res = cs[i] + 5.0 * res;
    }
    return res;
}

void run_benchmark() {
    for (int i = 0; i < 20000; i++) {
        double result = polynomial_evaluation();
        std::cout << result << std::endl;
    }
}

void cleanup() {
    cs.clear();
}

int main(int argc, char *argv[]) {
    n = std::atoi(argv[2]);
    int iterations = std::atoi(argv[1]);
    for (int i = 0; i < iterations; i++) {
        initialize();
        start_rapl();
        run_benchmark();
        stop_rapl();
        cleanup();
    }

    return 0;
}
