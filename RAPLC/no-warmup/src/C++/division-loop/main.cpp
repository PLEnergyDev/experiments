#include <iostream>
#include <cstdlib>

double DivisionLoop(int M) {
    double sum = 0.0;
    int n = 0;
    while (sum < M) {
        n++;
        sum += 1.0 / n;
    }
    return n;
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <M>" << std::endl;
        return 1;
    }

    int M = std::atoi(argv[1]);
    for (int i = 0; i < 10; i++) {
        double result = DivisionLoop(M);
        std::cout << result << std::endl;
    }

    return 0;
}
