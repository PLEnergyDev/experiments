// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// Contributed by Jeremy Zerfas

#define COMPLEMENT_LOOKUP \
  "                                                                "\
  " TVGH  CD  M KN   YSAABW R       TVGH  CD  M KN   YSAABW R"

#define READ_SIZE 16384

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <rapl-interface.h>

typedef intptr_t intnative_t;

static intnative_t next_Sequence_Number_To_Output;

static void process_Sequence(char * sequence, const intnative_t sequence_Size, const intnative_t sequence_Number){
   sequence = realloc(sequence, sequence_Size);
   char * front_Pos = sequence, * back_Pos = sequence + sequence_Size - 1;
   while(*front_Pos++ != '\n');
   while(*front_Pos == '\n' && front_Pos <= back_Pos) front_Pos++;
   while(*back_Pos == '\n' && front_Pos <= back_Pos) back_Pos--;
   while(front_Pos <= back_Pos){
      const char temp = COMPLEMENT_LOOKUP[(unsigned char)*front_Pos];
      *front_Pos = COMPLEMENT_LOOKUP[(unsigned char)*back_Pos];
      *back_Pos = temp;
      while(*++front_Pos == '\n');
      while(*--back_Pos == '\n');
   }
   #pragma omp flush(next_Sequence_Number_To_Output)
   while(sequence_Number != next_Sequence_Number_To_Output){
      #pragma omp flush(next_Sequence_Number_To_Output)
   }
   fwrite(sequence, 1, sequence_Size, stdout);
   next_Sequence_Number_To_Output++;
   #pragma omp flush(next_Sequence_Number_To_Output)
   free(sequence);
}

void initialize(){
    next_Sequence_Number_To_Output = 1;
    fseek(stdin, 0, SEEK_SET);
}

void run_benchmark(){
    #pragma omp parallel
    {
        #pragma omp single
        {
            intnative_t sequence_Capacity = READ_SIZE, sequence_Size = 0, sequence_Number = 1;
            char * sequence = malloc(sequence_Capacity);
            for(intnative_t bytes_Read; (bytes_Read = fread(&sequence[sequence_Size], 1, READ_SIZE, stdin)); ){
                for(char * sequence_Start; (sequence_Start = memchr(&sequence[sequence_Size], '>', bytes_Read)); ){
                    const intnative_t number_Of_Preceding_Bytes = sequence_Start - &sequence[sequence_Size];
                    sequence_Size += number_Of_Preceding_Bytes;
                    if(sequence_Size){
                        char * const new_Sequence = malloc(READ_SIZE);
                        memcpy(new_Sequence, sequence_Start, bytes_Read - number_Of_Preceding_Bytes);
                        #pragma omp task firstprivate(sequence, sequence_Size, sequence_Number)
                        {
                            process_Sequence(sequence, sequence_Size, sequence_Number);
                        }
                        sequence = new_Sequence;
                        sequence_Capacity = READ_SIZE;
                        sequence_Size = 0;
                        sequence_Number++;
                    }
                    sequence_Size++;
                    bytes_Read -= number_Of_Preceding_Bytes + 1;
                }
                sequence_Size += bytes_Read;
                if(sequence_Size > sequence_Capacity - READ_SIZE)
                    sequence = realloc(sequence, sequence_Capacity *= 2);
            }
            if(sequence_Size)
                process_Sequence(sequence, sequence_Size, sequence_Number);
            else
                free(sequence);
        }
    }
}

int main(int argc, char** argv) {
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
