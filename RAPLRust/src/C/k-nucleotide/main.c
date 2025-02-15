// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// Contributed by Jeremy Zerfas

#define MAXIMUM_OUTPUT_LENGTH 4096

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <htslib/khash.h>

void start_rapl();
void stop_rapl();

#define CUSTOM_HASH_FUNCTION(key) ((key) ^ (key)>>7)

KHASH_INIT(oligonucleotide, uint64_t, uint32_t, 1, CUSTOM_HASH_FUNCTION, kh_int64_hash_equal)

typedef intptr_t intnative_t;

typedef struct {
    uint64_t    key;
    uint32_t    value;
} element;

#define code_For_Nucleotide(nucleotide) (" \0 \1\3  \2"[nucleotide & 0x7])

#define nucleotide_For_Code(code) ("ACGT"[code & 0x3])

static int element_Compare(const element * const left_Element, const element * const right_Element){
    if(left_Element->value < right_Element->value) return 1;
    if(left_Element->value > right_Element->value) return -1;
    return left_Element->key > right_Element->key ? 1 : -1;
}

static void generate_Frequencies_For_Desired_Length_Oligonucleotides(
    const char * const polynucleotide, const intnative_t polynucleotide_Length,
    const intnative_t desired_Length_For_Oligonucleotides, char * const output){

    khash_t(oligonucleotide) * hash_Table=kh_init(oligonucleotide);

    uint64_t key=0;
    const uint64_t mask=((uint64_t)1<<2*desired_Length_For_Oligonucleotides)-1;

    for(intnative_t i=0; i<desired_Length_For_Oligonucleotides-1; i++)
        key=(key<<2 & mask) | polynucleotide[i];

    for(intnative_t i=desired_Length_For_Oligonucleotides-1; i<polynucleotide_Length; i++){
        key=(key<<2 & mask) | polynucleotide[i];
        int element_Was_Unused;
        const khiter_t k=kh_put(oligonucleotide, hash_Table, key, &element_Was_Unused);
        if(element_Was_Unused)
            kh_value(hash_Table, k)=1;
        else
            kh_value(hash_Table, k)++;
    }

    intnative_t elements_Array_Size=kh_size(hash_Table), i=0;
    element * elements_Array=malloc(elements_Array_Size*sizeof(element));
    uint32_t value;
    kh_foreach(hash_Table, key, value, elements_Array[i++]=((element){key, value}));

    kh_destroy(oligonucleotide, hash_Table);

    qsort(elements_Array, elements_Array_Size, sizeof(element),
          (int (*)(const void *, const void *)) element_Compare);

    for(intnative_t output_Position=0, i=0; i<elements_Array_Size; i++){
        char oligonucleotide[desired_Length_For_Oligonucleotides+1];
        for(intnative_t j=desired_Length_For_Oligonucleotides-1; j>-1; j--){
            oligonucleotide[j]=nucleotide_For_Code(elements_Array[i].key);
            elements_Array[i].key>>=2;
        }
        oligonucleotide[desired_Length_For_Oligonucleotides]='\0';

        output_Position+=snprintf(output+output_Position,
          MAXIMUM_OUTPUT_LENGTH-output_Position, "%s %.3f\n", oligonucleotide,
          100.0f*elements_Array[i].value/(polynucleotide_Length-desired_Length_For_Oligonucleotides+1));
    }

    free(elements_Array);
}

static void generate_Count_For_Oligonucleotide(
    const char * const polynucleotide, const intnative_t polynucleotide_Length,
    const char * const oligonucleotide, char * const output){
    const intnative_t oligonucleotide_Length=strlen(oligonucleotide);

    khash_t(oligonucleotide) * const hash_Table=kh_init(oligonucleotide);

    uint64_t key=0;
    const uint64_t mask=((uint64_t)1<<2*oligonucleotide_Length)-1;

    for(intnative_t i=0; i<oligonucleotide_Length-1; i++)
        key=(key<<2 & mask) | polynucleotide[i];

    for(intnative_t i=oligonucleotide_Length-1; i<polynucleotide_Length; i++){
        key=(key<<2 & mask) | polynucleotide[i];
        int element_Was_Unused;
        const khiter_t k=kh_put(oligonucleotide, hash_Table, key, &element_Was_Unused);
        if(element_Was_Unused)
            kh_value(hash_Table, k)=1;
        else
            kh_value(hash_Table, k)++;
    }

    key=0;
    for(intnative_t i=0; i<oligonucleotide_Length; i++)
        key=(key<<2) | code_For_Nucleotide(oligonucleotide[i]);

    khiter_t k=kh_get(oligonucleotide, hash_Table, key);
    uintmax_t count=k==kh_end(hash_Table) ? 0 : kh_value(hash_Table, k);
    snprintf(output, MAXIMUM_OUTPUT_LENGTH, "%ju\t%s", count, oligonucleotide);

    kh_destroy(oligonucleotide, hash_Table);
}

char buffer[4096];
intnative_t polynucleotide_Capacity;
intnative_t polynucleotide_Length;
char * polynucleotide;
char output_Buffer[7][MAXIMUM_OUTPUT_LENGTH];

void initialize(){
    polynucleotide_Capacity=1048576;
    polynucleotide_Length=0;
    polynucleotide=malloc(polynucleotide_Capacity);
    fseek(stdin, 0, SEEK_SET);
}

void run_benchmark(){
    while(fgets(buffer, sizeof(buffer), stdin) && memcmp(">THREE", buffer, sizeof(">THREE")-1));

    while(fgets(buffer, sizeof(buffer), stdin) && buffer[0]!='>'){
        for(intnative_t i=0; buffer[i]!='\0'; i++)
            if(buffer[i]!='\n')
                polynucleotide[polynucleotide_Length++]=code_For_Nucleotide(buffer[i]);

        if(polynucleotide_Capacity-polynucleotide_Length<sizeof(buffer))
            polynucleotide=realloc(polynucleotide, polynucleotide_Capacity*=2);
    }

    polynucleotide=realloc(polynucleotide, polynucleotide_Length);

    #pragma omp parallel sections
    {
        #pragma omp section
        generate_Count_For_Oligonucleotide(polynucleotide, polynucleotide_Length, "GGTATTTTAATTTATAGT", output_Buffer[6]);
        #pragma omp section
        generate_Count_For_Oligonucleotide(polynucleotide, polynucleotide_Length, "GGTATTTTAATT", output_Buffer[5]);
        #pragma omp section
        generate_Count_For_Oligonucleotide(polynucleotide, polynucleotide_Length, "GGTATT", output_Buffer[4]);
        #pragma omp section
        generate_Count_For_Oligonucleotide(polynucleotide, polynucleotide_Length, "GGTA", output_Buffer[3]);
        #pragma omp section
        generate_Count_For_Oligonucleotide(polynucleotide, polynucleotide_Length, "GGT", output_Buffer[2]);
        #pragma omp section
        generate_Frequencies_For_Desired_Length_Oligonucleotides(polynucleotide, polynucleotide_Length, 2, output_Buffer[1]);
        #pragma omp section
        generate_Frequencies_For_Desired_Length_Oligonucleotides(polynucleotide, polynucleotide_Length, 1, output_Buffer[0]);
    }

    for(intnative_t i=0; i<7; printf("%s\n", output_Buffer[i++]));
}

void cleanup(){
    free(polynucleotide);
}

int main(int argc, char** argv) {
   int iterations = atoi(argv[1]);
   for (int i = 0; i < iterations; ++i) {
        initialize();
        start_rapl();
        run_benchmark();
        stop_rapl();
        cleanup();
    }
    return 0;
}
