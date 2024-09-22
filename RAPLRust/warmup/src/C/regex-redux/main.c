#include <pcre.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void start_rapl();
void stop_rapl();

typedef struct {
  char *data;
  int capacity, size;
} string;

// Function for searching a src_String for a pattern, replacing it with some
// specified replacement, and storing the result in dst_String.
static void replace(char const *const pattern, char const *const replacement,
                    string const *const src_String, string *const dst_String,
                    pcre_jit_stack *const stack) {

  char const *error;
  int offset, pos = 0, match[3];
  int const replacement_Size = strlen(replacement);

  // Compile and study pattern.
  pcre *regex = pcre_compile(pattern, 0, &error, &offset, NULL);
  pcre_extra *aid = pcre_study(regex, PCRE_STUDY_JIT_COMPILE, &error);

  // Find each match of the pattern in src_String and append the characters
  // preceding each match and the replacement text to dst_String.
  while (pcre_jit_exec(regex, aid, src_String->data, src_String->size, pos, 0,
                       match, 3, stack) >= 0) {

    // Allocate more memory for dst_String if there is not enough space for
    // the characters preceding the match and the replacement text.
    while (dst_String->size + match[0] - pos + replacement_Size >
           dst_String->capacity)
      dst_String->data = realloc(dst_String->data, dst_String->capacity *= 2);

    // Append the characters preceding the match and the replacement text to
    // dst_String and update the size of dst_String.
    memcpy(dst_String->data + dst_String->size, src_String->data + pos,
           match[0] - pos);
    memcpy(dst_String->data + dst_String->size + match[0] - pos, replacement,
           replacement_Size);
    dst_String->size += match[0] - pos + replacement_Size;

    // Update pos to continue searching after the current match.
    pos = match[1];
  }

  pcre_free_study(aid);
  pcre_free(regex);

  // Allocate more memory for dst_String if there is not enough space for
  // the characters following the last match (or the entire src_String if
  // there was no match).
  while (dst_String->size + src_String->size - pos > dst_String->capacity)
    dst_String->data = realloc(dst_String->data, dst_String->capacity *= 2);

  // Append the characters following the last match (or the entire src_String
  // if there was no match) to dst_String and update the size of dst_String.
  memcpy(dst_String->data + dst_String->size, src_String->data + pos,
         src_String->size - pos);
  dst_String->size += src_String->size - pos;
}

int main(int argc, char **argv) {
  int count = atoi(argv[1]);
  string input = {malloc(16384), 16384}, sequences = {malloc(16384), 16384};
  
  // Read input from stdin once at the beginning
  for (int bytes_Read; 
       (bytes_Read = fread(input.data + input.size, 1, input.capacity - input.size, stdin)) > 0;) {
    if ((input.size += bytes_Read) == input.capacity)
      input.data = realloc(input.data, input.capacity *= 2);
  }

  // Main iteration loop
  for (int i = 0; i < count; i++) {
    start_rapl();

    // Define patterns to search and replace
    char const *const count_Info[] = {
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

    const char *const replace_Info[][2] = {
      {"tHa[Nt]", "<4>"},
      {"aND|caN|Ha[DS]|WaS", "<3>"},
      {"a[NSt]|BY", "<2>"},
      {"<[^>]*>", "|"},
      {"\\|[^|][^|]*\\|", "-"}
    };

    // Reset sequences size for each iteration
    sequences.size = 0;

#pragma omp parallel
    {
      pcre_jit_stack *const stack = pcre_jit_stack_alloc(16384, 16384);

// Find all sequence descriptions and new lines in input, replace them
// with empty strings, and store the result in the sequences string.
#pragma omp single
      {
        replace(">.*\\n|\\n", "", &input, &sequences, stack);
      }

// Perform all the replacements serially
#pragma omp single nowait
      {
        string prereplace_String = {malloc(sequences.capacity),
                                    sequences.capacity, sequences.size};
        string postreplace_String = {malloc(sequences.capacity),
                                     sequences.capacity};
        memcpy(prereplace_String.data, sequences.data, sequences.size);

        for (int i = 0; i < sizeof(replace_Info) / sizeof(char *[2]); i++) {
          replace(replace_Info[i][0], replace_Info[i][1], &prereplace_String,
                  &postreplace_String, stack);

          string const temp = prereplace_String;
          prereplace_String = postreplace_String;
          postreplace_String = temp;

          postreplace_String.size = 0;
        }

        // Final size of the replaced string
        int postreplace_Size = prereplace_String.size;

        free(prereplace_String.data);
        free(postreplace_String.data);
      }

// Count the patterns in parallel
#pragma omp for schedule(dynamic) ordered
      for (int i = 0; i < sizeof(count_Info) / sizeof(char *); i++) {
        char const *error;
        int offset, pos = 0, match[3], count = 0;

        pcre *regex = pcre_compile(count_Info[i], 0, &error, &offset, NULL);
        pcre_extra *aid = pcre_study(regex, PCRE_STUDY_JIT_COMPILE, &error);

        while (pcre_jit_exec(regex, aid, sequences.data, sequences.size, pos, 0,
                             match, 3, stack) >= 0) {
          count++;
          pos = match[1];
        }

        pcre_free_study(aid);
        pcre_free(regex);

#pragma omp ordered
        printf("%s %d\n", count_Info[i], count);
      }

      pcre_jit_stack_free(stack);
    }

    // Print the sizes of the original, processed input, and replaced string
    printf("\n%d\n%d\n%d\n", input.size, sequences.size, sequences.size);
    
    stop_rapl();
  }

  free(input.data);
  free(sequences.data);
  return 0;
}
