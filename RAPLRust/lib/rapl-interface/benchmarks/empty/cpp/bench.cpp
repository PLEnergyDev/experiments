#include <iostream>

extern "C" {
    void start_rapl();
    void stop_rapl();
}

int main(int argc, char *argv[]) {
    int count = std::atoi(argv[1]);

    for (int i = 0; i < count; i++) {
        start_rapl();
        stop_rapl();
    }

    return 0;
}
