#include <iostream>
#include <algorithm>
#include <vector>
#include <functional>
#include <iostream>

extern "C" {
    void start_rapl();
    void stop_rapl();
}

// test method (our own implementation)
unsigned int fibonacci(unsigned int n) {
    if (n <= 1){
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

int main(int argc, char *argv[]) {
    unsigned int fib_param = std::atoi(argv[2]);
    int count = std::atoi(argv[1]);

    for (int i = 0; i < count; i++) {
        start_rapl();
        unsigned int result = fibonacci(fib_param);

        stop_rapl();

        // stopping compiler optimization
        if (result < 42){
            std::cout << "Result: " << result << std::endl;
        }
    }

    return 0;
}
