#include <iostream>
#include <vector>

std::vector<double> init_cs(int n) {
    std::vector<double> cs(n);
    for (int i = 0; i < n; i++) {
        cs[i] = 1.1 * i;
        if (i % 3 == 0) {
            cs[i] *= -1;
        }
    }
    return cs;
}

double polynomial_evaluation(int n) {
    std::vector<double> cs = init_cs(n);
    double res = 0.0;

    for (int i = 0; i < n; i++) {
        res = cs[i] + 5.0 * res;
    }

    return res;
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <n>" << std::endl;
        return 1;
    }

    int n = std::atoi(argv[1]);
    for (int i = 0; i < 1000; i++) {
        double result = polynomial_evaluation(n);
        std::cout << result << std::endl;
    }

    return 0;
}
