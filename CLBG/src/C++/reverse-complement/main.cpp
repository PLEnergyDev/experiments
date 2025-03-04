// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// contributed by Adam Kewley

#include <iostream>
#include <string>
#include <vector>
#include <sstream>
#include <rapl-interface.h>

#ifdef SIMD
#include <immintrin.h>
#endif

namespace {
    using std::istream;
    using std::ostream;
    using std::runtime_error;
    using std::string;
    using std::bad_alloc;
    using std::vector;

    constexpr size_t basepairs_in_line = 60;
    constexpr size_t line_len = basepairs_in_line + sizeof('\n');

    class unsafe_vector {
    public:
        unsafe_vector() {
            _buf = (char*)malloc(_capacity);
            if (_buf == nullptr) {
                throw bad_alloc{};
            }
        }

        unsafe_vector(const unsafe_vector& other) = delete;
        unsafe_vector(unsafe_vector&& other) = delete;
        unsafe_vector& operator=(unsafe_vector& other) = delete;
        unsafe_vector& operator=(unsafe_vector&& other) = delete;

        ~unsafe_vector() noexcept {
            free(_buf);
        }

        char* data() {
            return _buf;
        }

        void resize_UNSAFE(size_t count) {
            size_t rem = _capacity - _size;
            if (count > rem) {
                grow(count);
            }
            _size = count;
        }

        size_t size() const {
            return _size;
        }

    private:
        void grow(size_t min_cap) {
            size_t new_cap = _capacity;
            while (new_cap < min_cap) {
                new_cap *= 2;
            }

            char* new_buf = (char*)realloc(_buf, new_cap);
            if (new_buf != nullptr) {
                _capacity = new_cap;
                _buf = new_buf;
            } else {
                throw bad_alloc{};
            }
        }

        char* _buf = nullptr;
        size_t _size = 0;
        size_t _capacity = 1024;
    };

    char complement(char character) {
        static const char complement_lut[] = {
            '\0', '\0', '\0', '\0',  '\0', '\0', '\0', '\0',
            '\0', '\0', '\n', '\0',  '\0', '\0', '\0', '\0',
            '\0', '\0', '\0', '\0',  '\0', '\0', '\0', '\0',
            '\0', '\0', '\0', '\0',  '\0', '\0', '\0', '\0',

            '\0', '\0', '\0', '\0',  '\0', '\0', '\0', '\0',
            '\0', '\0', '\0', '\0',  '\0', '\0', '\0', '\0',
            '\0', '\0', '\0', '\0',  '\0', '\0', '\0', '\0',
            '\0', '\0', '\0', '\0',  '\0', '\0', '\0', '\0',

            '\0', 'T', 'V', 'G',     'H', '\0', '\0', 'C',
            'D', '\0', '\0', 'M',    '\0', 'K', 'N', '\0',
            '\0', '\0', 'Y', 'S',    'A', 'A', 'B', 'W',
            '\0', 'R', '\0', '\0',   '\0', '\0', '\0', '\0',

            '\0', 'T', 'V', 'G',     'H', '\0', '\0', 'C',
            'D', '\0', '\0', 'M',   '\0', 'K', 'N', '\0',
            '\0', '\0', 'Y', 'S',    'A', 'A', 'B', 'W',
            '\0', 'R', '\0', '\0',   '\0', '\0', '\0', '\0'
        };

        return complement_lut[character];
    }

    void complement_swap(char* a, char* b) {
        char tmp = complement(*a);
        *a = complement(*b);
        *b = tmp;
    }

#ifdef SIMD
    __m128i packed(char c) {
        return _mm_set1_epi8(c);
    }

    __m128i reverse_complement_simd(__m128i v) {
        v = _mm_shuffle_epi8(v, _mm_setr_epi8(
            15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0));

        v = _mm_and_si128(v, packed(0x1f));

        __m128i lt16_mask = _mm_cmplt_epi8(v, packed(16));
        __m128i lt16_els = _mm_and_si128(v, lt16_mask);
        __m128i lt16_lut = _mm_setr_epi8(
            '\0', 'T', 'V', 'G', 'H', '\0', '\0', 'C',
            'D', '\0', '\0', 'M', '\0', 'K', 'N', '\0');
        __m128i lt16_vals = _mm_shuffle_epi8(lt16_lut, lt16_els);

        __m128i g16_els = _mm_sub_epi8(v, packed(16));
        __m128i g16_lut = _mm_setr_epi8(
            '\0', '\0', '\0', '\0', '\0', '\0', 'R', '\0',
            'W', 'B', 'A', 'A', 'S', 'Y', '\0', '\0');
        __m128i g16_vals = _mm_shuffle_epi8(g16_lut, g16_els);

        return _mm_or_si128(lt16_vals, g16_vals);
    }
#endif

    void reverse_complement_bps(char* start, char* end, size_t num_bps) {
#ifdef SIMD
        while (num_bps >= 16) {
            end -= 16;

            __m128i tmp = _mm_loadu_si128((__m128i*)start);
            _mm_storeu_si128((__m128i*)start, reverse_complement_simd(_mm_loadu_si128((__m128i*)end)));
            _mm_storeu_si128((__m128i*)end, reverse_complement_simd(tmp));

            num_bps -= 16;
            start += 16;
        }
#endif
        while (num_bps >= 1) {
            complement_swap(start++, --end);
            num_bps -= 1;
        }
    }

    struct Sequence {
        string header;
        unsafe_vector seq;
    };

    void reverse_complement(Sequence& s) {
        char* begin = s.seq.data();
        char* end = s.seq.data() + s.seq.size();

        if (begin == end) {
            return;
        }

        size_t len = end - begin;
        size_t trailer_len = len % line_len;

        end--;

        if (trailer_len == 0) {
            size_t num_pairs = len / 2;
            reverse_complement_bps(begin, end, num_pairs);

            bool has_middle_bp = (len % 2) > 0;
            if (has_middle_bp) {
                begin[num_pairs] = complement(begin[num_pairs]);
            }

            return;
        }

        size_t trailer_bps = trailer_len > 0 ? trailer_len - 1 : 0;

        size_t rem_bps = basepairs_in_line - trailer_bps;
        size_t rem_bytes = rem_bps + 1;

        size_t num_whole_lines = len / line_len;
        size_t num_steps = num_whole_lines / 2;

        for (size_t i = 0; i < num_steps; ++i) {
            reverse_complement_bps(begin, end, trailer_bps);
            begin += trailer_bps;
            end -= trailer_len;

            reverse_complement_bps(begin, end, rem_bps);
            begin += rem_bytes;
            end -= rem_bps;
        }

        bool has_unpaired_line = (num_whole_lines % 2) > 0;
        if (has_unpaired_line) {
            reverse_complement_bps(begin, end, trailer_bps);
            begin += trailer_bps;
            end -= trailer_len;
        }

        size_t bps_in_last_line = end - begin;
        size_t swaps_in_last_line = bps_in_last_line / 2;
        reverse_complement_bps(begin, end, swaps_in_last_line);

        bool has_unpaired_byte = (bps_in_last_line % 2) > 0;
        if (has_unpaired_byte) {
            begin[swaps_in_last_line] = complement(begin[swaps_in_last_line]);
        }
    }

    void read_up_to(istream& in, unsafe_vector& out, char delim) {
        constexpr size_t read_size = 1 << 16;

        size_t bytes_read = 0;
        out.resize_UNSAFE(read_size);
        while (in) {
            in.getline(out.data() + bytes_read, read_size, delim);
            bytes_read += in.gcount();

            if (in.fail()) {
                out.resize_UNSAFE(bytes_read + read_size);
                in.clear(in.rdstate() & ~std::ios::failbit);
            } else if (in.eof()) {
                break;
            } else {
                --bytes_read;
                break;
            }
        }
        out.resize_UNSAFE(bytes_read);
    }

    void read_sequence(istream& in, Sequence& out) {
        out.header.clear();
        std::getline(in, out.header);
        read_up_to(in, out.seq, '>');
    }

    void write_sequence(ostream& out, Sequence& s) {
        out << '>';
        out << s.header;
        out << '\n';
        out.write(s.seq.data(), s.seq.size());
    }
}

namespace revcomp {
    void reverse_complement_fasta_stream(istream& in, ostream& out) {
        char c = in.get();
        if (c != '>') {
            throw runtime_error{"unexpected input: next char should be the start of a sequence header"};
        }
        in.unget();

        Sequence s;
        while (not in.eof()) {
            read_sequence(in, s);
            reverse_complement(s);
            write_sequence(out, s);
        }
    }
}

#include <fstream>

std::string input_data;

void run_benchmark() {
    std::istringstream in(input_data);
    revcomp::reverse_complement_fasta_stream(in, std::cout);
}

int main(int argc, char *argv[]) {
    // Read input data once
    std::cin.sync_with_stdio(false);
    std::cout.sync_with_stdio(false);
    input_data.assign(std::istreambuf_iterator<char>(std::cin), std::istreambuf_iterator<char>());

    while (1) {
        if (start_rapl() == 0) {
            break;
        }
        run_benchmark();
        stop_rapl();
    }
    return 0;
}
