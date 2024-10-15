#include <algorithm>
#include <array>
#include <atomic>
#include <functional>
#include <iostream>
#include <mutex>
#include <numeric>
#include <thread>
#include <vector>

extern "C" {
void start_rapl();
void stop_rapl();
}

struct IUB {
  float p;
  char c;
};

const std::string alu = {"GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG"
                         "GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA"
                         "CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT"
                         "ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA"
                         "GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG"
                         "AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC"
                         "AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA"};

std::array<IUB, 15> iub = {{
    {0.27f, 'a'}, {0.12f, 'c'}, {0.12f, 'g'}, {0.27f, 't'}, {0.02f, 'B'},
    {0.02f, 'D'}, {0.02f, 'H'}, {0.02f, 'K'}, {0.02f, 'M'}, {0.02f, 'N'},
    {0.02f, 'R'}, {0.02f, 'S'}, {0.02f, 'V'}, {0.02f, 'W'}, {0.02f, 'Y'}
}};

std::array<IUB, 4> homosapiens = {{
    {0.3029549426680f, 'a'},
    {0.1979883004921f, 'c'},
    {0.1975473066391f, 'g'},
    {0.3015094502008f, 't'}
}};

const int IM = 139968;
const float IM_RECIPROCAL = 1.0f / IM;

class RandomGenerator {
public:
  using result_t = uint32_t;
  RandomGenerator(int seed = 42) : last(seed) {}
  result_t operator()() {
    last = (last * IA + IC) % IM;
    return last;
  }

private:
  static const int IA = 3877, IC = 29573;
  int last;
};

char convert_trivial(char c) { return c; }

template <class iterator_type>
class repeat_generator_type {
public:
  using result_t = char;

  repeat_generator_type(iterator_type first, iterator_type last)
      : first(first), current(first), last(last) {}
  result_t operator()() {
    if (current == last)
      current = first;
    iterator_type p = current;
    ++current;
    return *p;
  }

private:
  iterator_type first;
  iterator_type current;
  iterator_type last;
};

template <class iterator_type>
repeat_generator_type<iterator_type> make_repeat_generator(iterator_type first,
                                                           iterator_type last) {
  return repeat_generator_type<iterator_type>(first, last);
}

template <class iterator_type>
char convert_random(uint32_t random, iterator_type begin, iterator_type end) {
  const float p = random * IM_RECIPROCAL;
  auto result = std::find_if(begin, end, [p](IUB i) { return p <= i.p; });
  return result->c;
}

char convert_IUB(uint32_t random) {
  return convert_random(random, iub.begin(), iub.end());
}

char convert_homosapiens(uint32_t random) {
  return convert_random(random, homosapiens.begin(), homosapiens.end());
}

template <class iterator_type>
void make_cumulative(iterator_type first, iterator_type last) {
  std::partial_sum(first, last, first, [](IUB l, IUB r) -> IUB {
    r.p += l.p;
    return r;
  });
}

const size_t CHARS_PER_LINE = 60;
const size_t VALUES_PER_BLOCK = CHARS_PER_LINE * 1024; // Adjusted block size

const unsigned THREADS_TO_USE =
    std::max(1U, std::thread::hardware_concurrency());

template <class generator_type, class converter_type>
void work(std::atomic<size_t> &totalValuesToGenerate, generator_type &generator,
          converter_type &converter, std::mutex &outputMutex) {
  std::array<typename generator_type::result_t, VALUES_PER_BLOCK> block;
  std::array<char, VALUES_PER_BLOCK + VALUES_PER_BLOCK / CHARS_PER_LINE + 1> characters;

  while (true) {
    size_t chunk_size = std::min(VALUES_PER_BLOCK, totalValuesToGenerate.load());
    if (chunk_size == 0) {
      break;
    }
    size_t oldTotal = totalValuesToGenerate.load();
    while (!totalValuesToGenerate.compare_exchange_weak(oldTotal, oldTotal - chunk_size)) {
      if (oldTotal == 0) {
        chunk_size = 0;
        break;
      }
      chunk_size = std::min(VALUES_PER_BLOCK, oldTotal);
    }
    if (chunk_size == 0) {
      break;
    }

    // Generate values
    for (size_t i = 0; i < chunk_size; ++i) {
      block[i] = generator();
    }

    // Convert and format output
    size_t charsGenerated = 0;
    size_t col = 0;
    for (size_t i = 0; i < chunk_size; ++i) {
      characters[charsGenerated++] = converter(block[i]);
      if (++col >= CHARS_PER_LINE) {
        characters[charsGenerated++] = '\n';
        col = 0;
      }
    }
    if (col != 0) {
      characters[charsGenerated++] = '\n';
    }

    // Output the result
    {
      std::lock_guard<std::mutex> guard(outputMutex);
      std::fwrite(characters.data(), charsGenerated, 1, stdout);
    }
  }
}

template <class generator_type, class converter_type>
void make(const char *desc, int n, generator_type prototype_generator,
          converter_type converter) {
  std::cout << '>' << desc << '\n';

  std::atomic<size_t> totalValuesToGenerate(n);
  std::mutex outputMutex;

  // Create generator instances per thread
  std::vector<generator_type> generators;
  for (unsigned i = 0; i < THREADS_TO_USE; ++i) {
    generators.push_back(prototype_generator);
  }

  // Start threads
  std::vector<std::thread> threads;
  for (unsigned i = 0; i < THREADS_TO_USE; ++i) {
    threads.emplace_back(work<generator_type, converter_type>, std::ref(totalValuesToGenerate),
                         std::ref(generators[i]), std::ref(converter), std::ref(outputMutex));
  }

  for (auto &thread : threads) {
    thread.join();
  }
}

int main(int argc, char *argv[]) {
  if (argc < 3) {
    std::cerr << "usage: " << argv[0] << " count length\n";
    return 1;
  }

  int count = std::atoi(argv[1]);
  int n = std::atoi(argv[2]);

  if (n <= 0 || count <= 0) {
    std::cerr << "Invalid input parameters.\n";
    return 1;
  }

  // Precompute cumulative probabilities outside the loop
  make_cumulative(iub.begin(), iub.end());
  make_cumulative(homosapiens.begin(), homosapiens.end());

  for (int counter = 0; counter < count; counter++) {
    start_rapl();

    // Sequence ONE: Using the repeat generator
    auto repeatGen = make_repeat_generator(alu.begin(), alu.end());
    make("ONE Homo sapiens alu", n * 2, repeatGen, &convert_trivial);

    // Sequence TWO: Using RandomGenerator and convert_IUB
    RandomGenerator randGen1(42 + counter); // Seed with counter to vary sequences
    make("TWO IUB ambiguity codes", n * 3, randGen1, &convert_IUB);

    // Sequence THREE: Using RandomGenerator and convert_homosapiens
    RandomGenerator randGen2(42 + counter * 2);
    make("THREE Homo sapiens frequency", n * 5, randGen2, &convert_homosapiens);

    stop_rapl();
  }
  return 0;
}
