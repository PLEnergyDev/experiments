// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// Contributed by Jeremy Zerfas

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <pcre.h>

void start_rapl();
void stop_rapl();

typedef struct {
    char * data;
    int capacity, size;
} string;

static char *input_data;
static int input_size;

static string input, sequences;

static int postreplace_Size;

void initialize(void) {
    input.data = malloc(input_size);
    memcpy(input.data, input_data, input_size);
    input.capacity = input_size;
    input.size = input_size;
}

void replace(char const * const pattern, char const * const replacement
  , string const * const src_String, string * const dst_String
  , pcre_jit_stack * const stack){

    char const * error;
    int offset, pos=0, match[3];
    int const replacement_Size=strlen(replacement);

    pcre * regex=pcre_compile(pattern, 0, &error, &offset, NULL);
    pcre_extra * aid=pcre_study(regex, PCRE_STUDY_JIT_COMPILE, &error);

    while(pcre_jit_exec(regex, aid, src_String->data, src_String->size
      , pos, 0, match, 3, stack)>=0){

        while(dst_String->size+match[0]-pos+replacement_Size
          >dst_String->capacity)
            dst_String->data=realloc(dst_String->data, dst_String->capacity*=2);

        memcpy(dst_String->data+dst_String->size, src_String->data+pos
          , match[0]-pos);
        memcpy(dst_String->data+dst_String->size+match[0]-pos, replacement
          , replacement_Size);
        dst_String->size+=match[0]-pos+replacement_Size;

        pos=match[1];
    }

    pcre_free_study(aid);
    pcre_free(regex);

    while(dst_String->size+src_String->size-pos>dst_String->capacity)
        dst_String->data=realloc(dst_String->data, dst_String->capacity*=2);

    memcpy(dst_String->data+dst_String->size, src_String->data+pos
      , src_String->size-pos);
    dst_String->size+=src_String->size-pos;
}

void run_benchmark(void) {
    char const * const count_Info[]={
        "agggtaaa|tttaccct",
        "[cgt]gggtaaa|tttaccc[acg]",
        "a[act]ggtaaa|tttacc[agt]t",
        "ag[act]gtaaa|tttac[agt]ct",
        "agg[act]taaa|ttta[agt]cct",
        "aggg[acg]aaa|ttt[cgt]ccct",
        "agggt[cgt]aa|tt[acg]accct",
        "agggta[cgt]a|t[acg]taccct",
        "agggtaa[cgt]|[acg]ttaccct"
      }, * const replace_Info[][2]={
        {"tHa[Nt]", "<4>"},
        {"aND|caN|Ha[DS]|WaS", "<3>"},
        {"a[NSt]|BY", "<2>"},
        {"<[^>]*>", "|"},
        {"\\|[^|][^|]*\\|", "-"}
      };

    sequences.data = malloc(16384);
    sequences.capacity = 16384;
    sequences.size = 0;

    #pragma omp parallel
    {
        pcre_jit_stack * const stack=pcre_jit_stack_alloc(16384, 16384);

        #pragma omp single
        {
            replace(">.*\\n|\\n", "", &input, &sequences, stack);

            free(input.data);
        }

        #pragma omp single nowait
        {
            string prereplace_String={
                malloc(sequences.capacity), sequences.capacity, sequences.size
              }, postreplace_String={
                malloc(sequences.capacity), sequences.capacity
              };
            memcpy(prereplace_String.data, sequences.data, sequences.size);

            for(int i=0; i<sizeof(replace_Info)/sizeof(char * [2]); i++){

                replace(replace_Info[i][0], replace_Info[i][1]
                  , &prereplace_String, &postreplace_String, stack);

                string const temp=prereplace_String;
                prereplace_String=postreplace_String;
                postreplace_String=temp;

                postreplace_String.size=0;
            }

            postreplace_Size=prereplace_String.size;

            free(prereplace_String.data);
            free(postreplace_String.data);
        }

        #pragma omp for schedule(dynamic) ordered
        for(int i=0; i<sizeof(count_Info)/sizeof(char *); i++){

            char const * error;
            int offset, pos=0, match[3], count=0;

            pcre * regex=pcre_compile(count_Info[i], 0, &error, &offset, NULL);
            pcre_extra * aid=pcre_study(regex, PCRE_STUDY_JIT_COMPILE, &error);

            while(pcre_jit_exec(regex, aid, sequences.data, sequences.size
              , pos, 0, match, 3, stack)>=0){

                count++;

                pos=match[1];
            }

            pcre_free_study(aid);
            pcre_free(regex);

            #pragma omp ordered
            printf("%s %d\n", count_Info[i], count);
        }

        pcre_jit_stack_free(stack);
    }

    free(sequences.data);

    printf("\n%d\n%d\n%d\n", input.size, sequences.size, postreplace_Size);
}

void cleanup(void) {
    // All memory has been freed in run_benchmark
}

int main(int argc, char** argv) {
    int capacity = 16384;
    input_data = malloc(capacity);
    input_size = 0;

    for(int bytes_Read;
      (bytes_Read=fread(input_data+input_size, 1, capacity-input_size
      , stdin))>0;){
        input_size += bytes_Read;
        if (input_size == capacity)
            input_data = realloc(input_data, capacity *= 2);
    }

   int iterations = atoi(argv[1]);
   for (int i = 0; i < iterations; ++i) {
        initialize();
        start_rapl();
        run_benchmark();
        stop_rapl();
        cleanup();
    }

    free(input_data);

    return 0;
}
