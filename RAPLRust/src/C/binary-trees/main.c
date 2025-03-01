// The Computer Language Benchmarks Game
// http://benchmarksgame.alioth.debian.org/
//
// Contributed by Jeremy Zerfas
// Based on the C++ program from Jon Harrop, Alex Mizrahi, and Bruno Coutinho.
// Modified for multiple iterations with distinct phases

#define MAXIMUM_LINE_WIDTH  60

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <apr_pools.h>
#include <rapl-interface.h>

typedef off_t off64_t;

typedef intptr_t intnative_t;

typedef struct tree_node{
   struct tree_node   * left_Node, * right_Node;
} tree_node;

// Create a binary tree of depth tree_Depth in memory_Pool
static inline tree_node * create_Tree(const intnative_t tree_Depth, apr_pool_t * const memory_Pool) {
   tree_node * const root_Node = apr_palloc(memory_Pool, sizeof(tree_node));
   if(tree_Depth > 0) {
      root_Node->left_Node = create_Tree(tree_Depth-1, memory_Pool);
      root_Node->right_Node = create_Tree(tree_Depth-1, memory_Pool);
   } else {
      root_Node->left_Node = root_Node->right_Node = NULL;
   }
   return root_Node;
}

// Compute the checksum for the binary tree
static inline intnative_t compute_Tree_Checksum(const tree_node * const root_Node) {
   if(root_Node->left_Node)
      return compute_Tree_Checksum(root_Node->left_Node) + compute_Tree_Checksum(root_Node->right_Node) + 1;
   else
      return 1;
}

// Initialization phase
void initialize(intnative_t * maximum_Tree_Depth, int argc, char ** argv) {
   const intnative_t minimum_Tree_Depth = 4;
   *maximum_Tree_Depth = atoi(argv[1]);
   if (*maximum_Tree_Depth < minimum_Tree_Depth + 2)
      *maximum_Tree_Depth = minimum_Tree_Depth + 2;
   apr_initialize();
}

// Benchmark phase
void run_benchmark(intnative_t maximum_Tree_Depth) {
   apr_pool_t * memory_Pool;

   apr_pool_create_unmanaged(&memory_Pool);
   tree_node * stretch_Tree = create_Tree(maximum_Tree_Depth+1, memory_Pool);
   printf("stretch tree of depth %jd\t check: %jd\n", (intmax_t)maximum_Tree_Depth+1, (intmax_t)compute_Tree_Checksum(stretch_Tree));
   apr_pool_destroy(memory_Pool);

   apr_pool_create_unmanaged(&memory_Pool);
   tree_node * long_Lived_Tree = create_Tree(maximum_Tree_Depth, memory_Pool);

   char output_Buffer[maximum_Tree_Depth+1][MAXIMUM_LINE_WIDTH+1];
   intnative_t current_Tree_Depth;
   #pragma omp parallel for
   for(current_Tree_Depth = 4; current_Tree_Depth <= maximum_Tree_Depth; current_Tree_Depth += 2) {
      intnative_t iterations = 1 << (maximum_Tree_Depth - current_Tree_Depth + 4);
      apr_pool_t * thread_Memory_Pool;
      apr_pool_create_unmanaged(&thread_Memory_Pool);
      intnative_t i = 1, total_Trees_Checksum = 0;
      for(; i <= iterations; ++i) {
         tree_node * const tree_1 = create_Tree(current_Tree_Depth, thread_Memory_Pool);
         total_Trees_Checksum += compute_Tree_Checksum(tree_1);
         apr_pool_clear(thread_Memory_Pool);
      }
      apr_pool_destroy(thread_Memory_Pool);
      sprintf(output_Buffer[current_Tree_Depth], "%jd\t trees of depth %jd\t check: %jd\n", (intmax_t)iterations, (intmax_t)current_Tree_Depth, (intmax_t)total_Trees_Checksum);
   }
   for(current_Tree_Depth = 4; current_Tree_Depth <= maximum_Tree_Depth; current_Tree_Depth += 2)
      printf("%s", output_Buffer[current_Tree_Depth]);

   printf("long lived tree of depth %jd\t check: %jd\n", (intmax_t)maximum_Tree_Depth, (intmax_t)compute_Tree_Checksum(long_Lived_Tree));
   apr_pool_destroy(memory_Pool);
}

// Cleanup phase
void cleanup() {
   apr_terminate();
}

int main(int argc, char** argv) {
    int running = 1;
    while (running) {
        intnative_t maximum_Tree_Depth;
        initialize(&maximum_Tree_Depth, argc, argv);
        running = start_rapl();
        run_benchmark(maximum_Tree_Depth);
        stop_rapl();
        cleanup();
    }
    return 0;
}
