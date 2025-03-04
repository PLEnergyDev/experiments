/* The Computer Language Benchmarks Game
   https://salsa.debian.org/benchmarksgame-team/benchmarksgame/

   regex-dna program contributed by Alexey Zolotov
   modified by Vaclav Zeman
   converted from regex-dna program
*/

#include <boost/regex.hpp>
#include <cassert>
#include <iostream>
#include <cstdio>
#include <rapl-interface.h>

using namespace std;

const std::size_t BUFSIZE = 1024;
const boost::regex::flag_type re_flags = boost::regex::perl;

string original_str;
string str, out;
int len1, len2;
int read_size;
int counts[9];
const int pattern1_count = 9;
char const * pattern1[] = {
    "agggtaaa|tttaccct",
    "[cgt]gggtaaa|tttaccc[acg]",
    "a[act]ggtaaa|tttacc[agt]t",
    "ag[act]gtaaa|tttac[agt]ct",
    "agg[act]taaa|ttta[agt]cct",
    "aggg[acg]aaa|ttt[cgt]ccct",
    "agggt[cgt]aa|tt[acg]accct",
    "agggta[cgt]a|t[acg]taccct",
    "agggtaa[cgt]|[acg]ttaccct"
};

string const pattern2[] = {
    "tHa[Nt]", "<4>", "aND|caN|Ha[DS]|WaS", "<3>", "a[NSt]|BY", "<2>",
    "<[^>]*>", "|", "\\|[^|][^|]*\\|", "-"
};

void initialize()
{
    str = original_str;
    len1 = 0;
    len2 = 0;
    out.clear();
    for (int i = 0; i < pattern1_count; ++i)
        counts[i] = 0;
}

void run_benchmark()
{
    len1 = str.length();
    boost::regex re1 (">[^\\n]+\\n|[\\n]", re_flags);
    boost::regex_replace (str, re1, "").swap (str);
    len2 = str.length();

    out = str;

    #pragma omp parallel sections
    {
    #pragma omp section
        #pragma omp parallel for
        for (int i = 0; i < pattern1_count; i++)
        {
            boost::regex pat(pattern1[i], re_flags);
            boost::smatch m;
            std::string::const_iterator start = str.begin(), end = str.end(); 
            while (boost::regex_search(start, end, m, pat))
            {
                #pragma omp atomic
                ++counts[i];
                start += m.position() + m.length();
            }
        }
    #pragma omp section
        for (int i = 0; i < (int)(sizeof(pattern2) / sizeof(string)); i += 2)
        {
            boost::regex re(pattern2[i], re_flags);
            boost::regex_replace(out, re, pattern2[i + 1]).swap(out);
        }
    }

    for (int i = 0; i != pattern1_count; ++i)
        cout << pattern1[i] << " " << counts[i] << "\n";

    cout << "\n";
    cout << len1 << "\n";
    cout << len2 << "\n";
    cout << out.length() << endl;
}

int main(int argc, char *argv[]) {
    fseek(stdin, 0, SEEK_END);
    read_size = ftell(stdin);
    assert(read_size > 0);

    original_str.resize(read_size);
    rewind(stdin);
    read_size = fread(&original_str[0], 1, read_size, stdin);
    assert(read_size);
    while (1) {
        initialize();
        if (start_rapl() == 0) {
            break;
        }
        run_benchmark();
        stop_rapl();
    }

    return 0;
}
