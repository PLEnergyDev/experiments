// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// Contributed by Dave Compton
// Based on "fannkuch-redux C gcc #5", contributed by Jeremy Zerfas
// which in turn was based on the Ada program by Jonathan Parker and 
// Georg Bauhaus which in turn was based on code by Dave Fladebo, 
// Eckehard Berns, Heiner Marxen, Hongwei Xi, and The Anh Tran and 
// also the Java program by Oleg Mazurov.

#include <iostream>
#include <vector>
#include <algorithm>
#include <rapl-interface.h>

using namespace std;

static int64_t fact[32];

void initializeFact(int n)
{
    fact[0] = 1;
    for (auto i = 1; i <= n; ++i)
        fact[i] = i * fact[i - 1];
}

class Permutation
{
  public:
    Permutation(int n, int64_t start);
    void advance();
    int64_t countFlips() const;

  private:
     vector<int> count;
     vector<int8_t> current;
};

Permutation::Permutation(int n, int64_t start)
{
    count.resize(n);
    current.resize(n);

    for (auto i = n - 1; i >= 0; --i)
    {
        auto d = start / fact[i];
        start = start % fact[i];
        count[i] = d;
    }

    for (auto i = 0; i < n; ++i)
        current[i] = i;

    for (auto i = n - 1; i >= 0; --i)
    {
        auto d = count[i];
        auto b = current.begin();
        rotate(b, b + d, b + i + 1);
    }
}

void Permutation::advance()
{
    for (auto i = 1; ; ++i)
    {
        auto first = current[0];
        for (auto j = 0; j < i; ++j)
            current[j] = current[j + 1];
        current[i] = first;

        ++(count[i]);
        if (count[i] <= i)
            break;
        count[i] = 0;
    }
}

inline int64_t Permutation::countFlips() const
{
    const auto n = current.size();
    auto flips = 0;
    auto first = current[0];
    if (first > 0)
    {
        flips = 1;

        int8_t temp[n];
        for (size_t i = 0; i < n; ++i)
            temp[i] = current[i];

        for (; temp[first] > 0; ++flips)
        {
            const int8_t newFirst = temp[first];
            temp[first] = first;

            if (first > 2)
            {
                int64_t low = 1, high = first - 1;
                do
                {
                    swap(temp[low], temp[high]);
                    if (!(low + 3 <= high && low < 16))
                        break;
                    ++low;
                    --high;
                } while (1);
            }
            first = newFirst;
        }
    }
    return flips;
}

int64_t maxFlips;
int64_t checksum;
int64_t blockLength;
int64_t blockCount;

void initialize(int n)
{
    initializeFact(n);

    blockCount = 24;
    if (blockCount > fact[n])
        blockCount = 1;
    blockLength = fact[n] / blockCount;

    maxFlips = 0;
    checksum = 0;
}

void run_benchmark(int n)
{
    #pragma omp parallel for \
        reduction(max:maxFlips) \
        reduction(+:checksum)

    for (int64_t blockStart = 0;
         blockStart < fact[n];
         blockStart += blockLength)
    {
        Permutation permutation(n, blockStart);

        auto index = blockStart;
        while (1)
        {
            const auto flips = permutation.countFlips();

            if (flips)
            {
                if (index % 2 == 0)
                    checksum += flips;
                else
                    checksum -= flips;

                if (flips > maxFlips)
                    maxFlips = flips;
            }

            if (++index == blockStart + blockLength)
                break;

            permutation.advance();
        }
    }

    cout << checksum << endl;
    cout << "Pfannkuchen(" << n << ") = " << maxFlips << endl;
}

int main(int argc, char **argv)
{
    int n = atoi(argv[1]);
    while (1) {
        initialize(n);
        if (start_rapl() == 0) {
            break;
        }
        run_benchmark(n);
        stop_rapl();
    }

    return 0;
}
