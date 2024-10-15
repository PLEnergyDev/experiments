#define COMPLEMENT_LOOKUP \
  "                                                                "\
  " TVGH  CD  M KN   YSAABW R       TVGH  CD  M KN   YSAABW R"

#define READ_SIZE 16384

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

void start_rapl();
void stop_rapl();

typedef intptr_t intnative_t;

static volatile intnative_t next_Sequence_Number_To_Output = 1;

static void process_Sequence(char *sequence, const intnative_t sequence_Size,
                             const intnative_t sequence_Number) {
   sequence = realloc(sequence, sequence_Size);

   char *front_Pos = sequence, *back_Pos = sequence + sequence_Size - 1;

   // Move front_Pos to the first character after the initial header line.
   while (front_Pos < sequence + sequence_Size && *front_Pos++ != '\n');
   if (front_Pos >= sequence + sequence_Size) {
      // No sequence data found
      return;
   }

   // Adjust front_Pos and back_Pos to skip over any newline characters.
   while (front_Pos < sequence + sequence_Size && *front_Pos == '\n') front_Pos++;
   while (back_Pos > sequence && *back_Pos == '\n') back_Pos--;

   while (front_Pos < back_Pos) {
      const char temp = COMPLEMENT_LOOKUP[(unsigned char)*front_Pos];
      *front_Pos = COMPLEMENT_LOOKUP[(unsigned char)*back_Pos];
      *back_Pos = temp;

      do { front_Pos++; } while (front_Pos < back_Pos && *front_Pos == '\n');
      do { back_Pos--; } while (front_Pos < back_Pos && *back_Pos == '\n');
   }

   if (front_Pos == back_Pos) {
      *front_Pos = COMPLEMENT_LOOKUP[(unsigned char)*front_Pos];
   }

   #pragma omp flush(next_Sequence_Number_To_Output)
   while (sequence_Number != next_Sequence_Number_To_Output) {
      #pragma omp flush(next_Sequence_Number_To_Output)
   }
   fwrite(sequence, 1, sequence_Size, stdout);
   next_Sequence_Number_To_Output++;
   #pragma omp flush(next_Sequence_Number_To_Output)

   free(sequence);
}

int main(int argc, char **argv) {
   char *input_data = NULL;
   size_t input_size = 0;
   size_t bytes_read;
   char read_buffer[READ_SIZE];

   while ((bytes_read = fread(read_buffer, 1, READ_SIZE, stdin)) > 0) {
      char *new_input_data = realloc(input_data, input_size + bytes_read);
      if (!new_input_data) {
         fprintf(stderr, "Memory allocation error\n");
         free(input_data);
         return 1;
      }
      input_data = new_input_data;
      memcpy(input_data + input_size, read_buffer, bytes_read);
      input_size += bytes_read;
   }

   if (input_size == 0) {
      fprintf(stderr, "No input data\n");
      return 1;
   }

      next_Sequence_Number_To_Output = 1;

      int error_occurred = 0;

      #pragma omp parallel shared(error_occurred)
      {
         #pragma omp single
         {
            intnative_t sequence_Capacity = READ_SIZE, sequence_Size = 0, sequence_Number = 1;
            char *sequence = malloc(sequence_Capacity);

            if (!sequence) {
               fprintf(stderr, "Memory allocation error\n");
               error_occurred = 1;
            } else {
               size_t offset = 0;

               while (offset < input_size && !error_occurred) {
                  size_t bytes_to_copy = input_size - offset;
                  if (bytes_to_copy > READ_SIZE) bytes_to_copy = READ_SIZE;

                  if (sequence_Size + bytes_to_copy > sequence_Capacity) {
                     sequence_Capacity = (sequence_Size + bytes_to_copy) * 2;
                     char *new_sequence = realloc(sequence, sequence_Capacity);
                     if (!new_sequence) {
                        fprintf(stderr, "Memory allocation error\n");
                        free(sequence);
                        error_occurred = 1;
                        break;
                     }
                     sequence = new_sequence;
                  }

                  memcpy(&sequence[sequence_Size], input_data + offset, bytes_to_copy);
                  offset += bytes_to_copy;

                  intnative_t bytes_Read = bytes_to_copy;
                  sequence_Size += bytes_Read;

                  char *sequence_Start = sequence;
                  while (1) {
                     // Search for the next '>' indicating a new sequence.
                     char *next_seq = memchr(sequence_Start + 1, '>', (sequence + sequence_Size) - (sequence_Start + 1));
                     if (next_seq == NULL) {
                        // No more sequences in the current buffer.
                        break;
                     }

                     // Calculate the size of the current sequence.
                     intnative_t current_sequence_size = next_seq - sequence_Start;

                     if (current_sequence_size > 0) {
                        // Copy the sequence data to a new buffer.
                        char *sequence_copy = malloc(current_sequence_size);
                        if (!sequence_copy) {
                           fprintf(stderr, "Memory allocation error\n");
                           free(sequence);
                           error_occurred = 1;
                           break;
                        }
                        memcpy(sequence_copy, sequence_Start, current_sequence_size);

                        #pragma omp task firstprivate(sequence_copy, current_sequence_size, sequence_Number)
                        {
                           process_Sequence(sequence_copy, current_sequence_size, sequence_Number);
                        }

                        sequence_Number++;
                     }

                     sequence_Start = next_seq;
                  }

                  // Move any remaining data to the beginning of the buffer.
                  intnative_t remaining_data_size = (sequence + sequence_Size) - sequence_Start;
                  memmove(sequence, sequence_Start, remaining_data_size);
                  sequence_Size = remaining_data_size;
                  sequence_Start = sequence;

                  if (sequence_Size > sequence_Capacity - READ_SIZE) {
                     sequence_Capacity = sequence_Size + READ_SIZE;
                     char *new_sequence = realloc(sequence, sequence_Capacity);
                     if (!new_sequence) {
                        fprintf(stderr, "Memory allocation error\n");
                        free(sequence);
                        error_occurred = 1;
                        break;
                     }
                     sequence = new_sequence;
                  }
               }

               if (!error_occurred) {
                  if (sequence_Size > 0) {
                     // Process the last sequence.
                     char *sequence_copy = malloc(sequence_Size);
                     if (!sequence_copy) {
                        fprintf(stderr, "Memory allocation error\n");
                        free(sequence);
                        error_occurred = 1;
                     } else {
                        memcpy(sequence_copy, sequence, sequence_Size);

                        #pragma omp task firstprivate(sequence_copy, sequence_Size, sequence_Number)
                        {
                           process_Sequence(sequence_copy, sequence_Size, sequence_Number);
                        }
                     }
                  }

                  #pragma omp taskwait
               }

               free(sequence);
            }
         }
      }

      if (error_occurred) {
         free(input_data);
         return 1;
      }

   free(input_data);
   return 0;
}
