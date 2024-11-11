// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// Contributed by Kevin Miller (as C code)
//
// Ported to C++ with minor changes by Dave Compton

#include <immintrin.h>
#include <iostream>

extern "C" {
    void start_rapl();
    void stop_rapl();
}

#ifdef __AVX__
#define VEC_SIZE 4
typedef __m256d Vec;
#define VEC_INIT(value) (Vec){value, value, value, value}
#else
#define VEC_SIZE 2
typedef __m128d Vec;
#define VEC_INIT(value) (Vec){value, value}
#endif

#define LOOP_SIZE (8 / VEC_SIZE)

using namespace std;

bool vec_le(double *v, double f)
{
    return (
        v[0] <= f ||
        v[1] <= f ||
        v[2] <= f ||
        v[3] <= f ||
        v[4] <= f ||
        v[5] <= f ||
        v[6] <= f ||
        v[7] <= f);
}

int8_t pixels(double *v, double f)
{
    int8_t res = 0;
    if (v[0] <= f)
        res |= 0b10000000;
    if (v[1] <= f)
        res |= 0b01000000;
    if (v[2] <= f)
        res |= 0b00100000;
    if (v[3] <= f)
        res |= 0b00010000;
    if (v[4] <= f)
        res |= 0b00001000;
    if (v[5] <= f)
        res |= 0b00000100;
    if (v[6] <= f)
        res |= 0b00000010;
    if (v[7] <= f)
        res |= 0b00000001;
    return res;
}

inline void calcSum(double *r, double *i, double *sum, double const *init_r, Vec const &init_i)
{
    auto r_v = (Vec *)r;
    auto i_v = (Vec *)i;
    auto sum_v = (Vec *)sum;
    auto init_r_v = (Vec const *)init_r;

    for (auto vec = 0; vec < LOOP_SIZE; vec++)
    {
        auto r2 = r_v[vec] * r_v[vec];
        auto i2 = i_v[vec] * i_v[vec];
        auto ri = r_v[vec] * i_v[vec];

        sum_v[vec] = r2 + i2;

        r_v[vec] = r2 - i2 + init_r_v[vec];
        i_v[vec] = ri + ri + init_i;
    }
}

inline int8_t mand8(double *init_r, double iy)
{
    double r[8], i[8], sum[8];
    for (auto k = 0; k < 8; k++)
    {
        r[k] = init_r[k];
        i[k] = iy;
    }

    auto init_i = VEC_INIT(iy);

    int8_t pix = 0xff;

    for (auto j = 0; j < 10; j++)
    {
        for (auto k = 0; k < 5; k++)
            calcSum(r, i, sum, init_r, init_i);

        if (!vec_le(sum, 4.0))
        {
            pix = 0x00;
            break;
        }
    }
    if (pix)
    {
        pix = pixels(sum, 4.0);
    }

    return pix;
}

void initialize(int wid_ht, double *&r0, char *&pixels, size_t &dataLength)
{
    dataLength = wid_ht * (wid_ht >> 3);
    pixels = new char[dataLength];
    r0 = new double[wid_ht];
    for (auto x = 0; x < wid_ht; x++)
    {
        r0[x] = 2.0 / wid_ht * x - 1.5;
    }
}

void run_benchmark(int wid_ht, double *r0, char *pixels)
{
#pragma omp parallel for schedule(guided)
    for (auto y = 0; y < wid_ht; y++)
    {
        auto iy = 2.0 / wid_ht * y - 1.0;
        auto rowstart = y * wid_ht / 8;
        for (auto x = 0; x < wid_ht; x += 8)
        {
            pixels[rowstart + x / 8] = mand8(r0 + x, iy);
        }
    }
}

void cleanup(int wid_ht, char *pixels, size_t dataLength, double *r0)
{
    cout << "P4\n" << wid_ht << " " << wid_ht << "\n";
    cout.write(pixels, dataLength);
    delete[] pixels;
    delete[] r0;
}

int main(int argc, char **argv)
{
    auto wid_ht = 16000;
    if (argc >= 2)
    {
        wid_ht = atoi(argv[2]);
    }
    wid_ht = (wid_ht + 7) & ~7;
    int iterations = atoi(argv[1]);
    for (int i = 0; i < iterations; i++)
    {
        double *r0 = nullptr;
        char *pixels = nullptr;
        size_t dataLength = 0;
        initialize(wid_ht, r0, pixels, dataLength);
        start_rapl();
        run_benchmark(wid_ht, r0, pixels);
        stop_rapl();
        cleanup(wid_ht, pixels, dataLength, r0);
    }
    return 0;
}
