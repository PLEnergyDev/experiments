#include <iostream>
#include <thread>
#include <chrono>

extern "C" {
    void start_rapl();
    void stop_rapl();
}

int main(int argc, char *argv[]) {
    int count = std::atoi(argv[1]);
    int sleep_time = std::atoi(argv[2]);

    for (int i = 0; i < count; i++) {
        start_rapl();
        std::this_thread::sleep_for (std::chrono::seconds(sleep_time));
        stop_rapl();
    }

    return 0;
}
