#include <iostream>
#include <algorithm>
#include <vector>
#include <functional>
#include <iostream>

extern "C" {
    void start_rapl();
    void stop_rapl();
}

// test method from Rosetta code
unsigned int fibonacci(unsigned int n) {
    if (n == 0) return 0;
    std::vector<int> v(n+1);
    v[1] = 1;
    transform(v.begin(), v.end()-2, v.begin()+1, v.begin()+2, std::plus<int>());
    // "v" now contains the Fibonacci sequence from 0 up
    return v[n];
}

int main(int argc, char *argv[]) {
    int fib_param = std::atoi(argv[2]);
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
