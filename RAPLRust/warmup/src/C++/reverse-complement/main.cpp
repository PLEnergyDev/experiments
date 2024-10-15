/* The Computer Language Benchmarks Game
   http://benchmarksgame.alioth.debian.org/

   Contributed by Andrew Moon
   Modified to allow multiple iterations without altering the core algorithm
*/

#include <cstdlib>
#include <cstdio>
#include <iostream>
#include <vector>
#include <cstring>
#include <pthread.h>
#include <algorithm>
#include <sched.h>
#include <ctype.h>
#include <unistd.h>

extern "C" {
void start_rapl();
void stop_rapl();
}

struct CPUs {
   CPUs() {
      cpu_set_t cs;
      CPU_ZERO(&cs);
      sched_getaffinity(0, sizeof(cs), &cs);
      count = 0;
      for (size_t i = 0; i < CPU_SETSIZE; i++)
         count += CPU_ISSET(i, &cs) ? 1 : 0;
      count = std::max(count, size_t(1));
   }

   size_t count;
} cpus;

struct ReverseLookup {
   ReverseLookup(const char *from, const char *to) {
      for (int i = 0; i < 256; i++)
         byteLookup[i] = i;
      for (; *from && *to; from++, to++) {
         byteLookup[toupper(*from)] = *to;
         byteLookup[tolower(*from)] = *to;
      }

      for (int i = 0; i < 256; i++)
         for (int j = 0; j < 256; j++)
            wordLookup[(i << 8) | j] = (byteLookup[j] << 8) | byteLookup[i];
   }

   char operator[](const char &c) { return (char)byteLookup[(unsigned char)c]; }
   short operator[](const short &s) { return (short)wordLookup[(unsigned short)s]; }

protected:
   unsigned char byteLookup[256];
   unsigned short wordLookup[256 * 256];
} lookup("acbdghkmnsrutwvy", "TGVHCDMKNSYAAWBR");

template <class type>
struct vector2 : public std::vector<type> {
   type &last() { return this->operator[](std::vector<type>::size() - 1); }
};

struct Chunker {
   enum { lineLength = 60, chunkSize = 65536 };

   Chunker(int seq, const char *data, size_t size, size_t &offset)
       : id(seq), inputData(data), dataSize(size), dataOffset(offset) {}

   struct Chunk {
      Chunk() {}
      Chunk(char *in, size_t amt) : data(in), size(amt) {}
      char *data;
      size_t size;
   };

   void NewChunk() {
      size_t cur = mark - chunkBase;
      chunks.push_back(Chunk(chunkBase, cur));
      chunkBase += (cur + (cur & 1)); // keep it word aligned
      mark = chunkBase;
   }

   template <int N>
   struct LinePrinter {
      LinePrinter() : lineFill(0) {}
      void endofblock() {
         if (lineFill)
            newline();
      }
      void emit(const char *str, size_t amt) {
         fwrite(str, 1, amt, stdout);
      }
      void emit(char c) { fputc(c, stdout); }
      void emitnewline() { emit('\n'); }
      void emitlines(char *data, size_t size) {
         if (lineFill) {
            size_t toprint = std::min(size, lineLength - lineFill);
            emit(data, toprint);
            size -= toprint;
            data += toprint;
            lineFill += toprint;
            if (lineFill == lineLength)
               newline();
         }

         while (size >= lineLength) {
            emit(data, lineLength);
            emitnewline();
            size -= lineLength;
            data += lineLength;
         }

         if (size) {
            lineFill = size;
            emit(data, size);
         }
      }
      void newline() {
         lineFill = 0;
         emitnewline();
      }
      void reset() { lineFill = 0; }

   protected:
      size_t lineFill;
   };

   void Print() {
      int prevId = -(id - 1);
      while (__sync_val_compare_and_swap(&printQueue, prevId, id) != prevId)
         sched_yield();

      fwrite(name, 1, strlen(name), stdout);
      static LinePrinter<65536 * 2> line;
      line.reset();
      for (int i = int(chunks.size()) - 1; i >= 0; i--)
         line.emitlines(chunks[i].data, chunks[i].size);
      line.endofblock();

      __sync_val_compare_and_swap(&printQueue, id, -id);
   }

   size_t Read(char *data, size_t dataCapacity) {
      if (dataOffset >= dataSize)
         return 0;

      name = data;

      // Read the name line
      size_t nameLen = 0;
      while (dataOffset < dataSize && inputData[dataOffset] != '\n') {
         name[nameLen++] = inputData[dataOffset++];
         if (nameLen >= dataCapacity) {
            fprintf(stderr, "Buffer overflow in Chunker::Read() (name)\n");
            exit(1);
         }
      }
      if (dataOffset < dataSize && inputData[dataOffset] == '\n') {
         name[nameLen++] = '\n';
         dataOffset++; // Skip the newline
      }
      name[nameLen] = '\0';
      mark = chunkBase = name + nameLen;

      // Ensure we do not exceed dataCapacity
      if (size_t(mark - data) + lineLength >= dataCapacity) {
         fprintf(stderr, "Buffer overflow in Chunker::Read() (initial)\n");
         exit(1);
      }

      mark[lineLength] = -1;

      // Read the sequence lines
      while (dataOffset < dataSize) {
         if (inputData[dataOffset] == '>') {
            // Found next sequence
            break;
         }

         size_t lineLen = 0;
         while (dataOffset < dataSize && inputData[dataOffset] != '\n') {
            mark[lineLen++] = inputData[dataOffset++];
            // Check for buffer overflow
            if (size_t(mark + lineLen - data) >= dataCapacity) {
               fprintf(stderr, "Buffer overflow in Chunker::Read() (sequence)\n");
               exit(1);
            }
         }
         if (dataOffset < dataSize && inputData[dataOffset] == '\n') {
            dataOffset++; // Skip the newline
         }
         mark[lineLen++] = '\n'; // Add newline
         mark += lineLen;

         if (mark - chunkBase > chunkSize)
            NewChunk();

         // Ensure we do not exceed dataCapacity
         if (size_t(mark - data) + lineLength >= dataCapacity) {
            fprintf(stderr, "Buffer overflow in Chunker::Read() (loop)\n");
            exit(1);
         }
         mark[lineLength] = -1;
      }

      if (mark - chunkBase)
         NewChunk();
      return (mark - data); // Return total bytes read into data
   }

   struct WorkerState {
      Chunker *chunker;
      size_t offset, count;
      pthread_t handle;
   };

   static void *ReverseWorker(void *arg) {
      WorkerState *state = (WorkerState *)arg;
      Chunker &chunker = *state->chunker;
      for (size_t i = 0; i < state->count; i++) {
         Chunk &chunk = chunker[state->offset + i];
         short *w = (short *)chunk.data, *bot = w, *top = w + (chunk.size / 2) - 1;
         for (; bot < top; bot++, top--) {
            short tmp = lookup[*bot];
            *bot = lookup[*top];
            *top = tmp;
         }
         // if size is odd, final byte would reverse to the start (skip it)
         if (chunk.size & 1)
            chunk.data++;
      }
      return 0;
   }

   void Reverse() {
      if (!chunks.size())
         return;

      vector2<WorkerState> workers;
      size_t numWorkers = std::min(cpus.count, chunks.size());
      workers.reserve(numWorkers);
      size_t divs = chunks.size() / numWorkers;
      size_t offset = 0;
      for (size_t i = 0; i < numWorkers; i++, offset += divs) {
         workers.push_back(WorkerState());
         WorkerState &ws = workers.last();
         ws.chunker = this;
         ws.count = (i < numWorkers - 1) ? divs : chunks.size() - offset;
         ws.offset = offset;
         pthread_create(&ws.handle, nullptr, ReverseWorker, &ws);
      }

      for (size_t i = 0; i < workers.size(); i++)
         pthread_join(workers[i].handle, nullptr);
   }

   Chunk &operator[](size_t i) { return chunks[i]; }

public:
   static volatile int printQueue;

protected:
   vector2<Chunk> chunks;
   char *name, *chunkBase, *mark;
   int id;
   const char *inputData;
   size_t dataSize;
   size_t &dataOffset;
};

volatile int Chunker::printQueue = 0;

struct ReverseComplement {
   ReverseComplement(const char *inputData, size_t inputSize)
       : data(inputData), size(inputSize) {}

   void Run() {
      vector2<Chunker *> chunkers;
      vector2<pthread_t> threads;

      // Allocate buffer to hold data read by chunkers
      std::vector<char> buffer;
      buffer.reserve(size * 2); // Reserve enough space

      size_t cur = 0;
      size_t dataOffset = 0;
      int id = 1;
      while (dataOffset < size) {
         chunkers.push_back(new Chunker(id++, data, size, dataOffset));

         // Expand buffer if necessary
         size_t bufferCapacity = buffer.capacity();
         if (cur + size - dataOffset + 10000 > bufferCapacity) {
            buffer.reserve(bufferCapacity + (size - dataOffset) * 2);
            bufferCapacity = buffer.capacity();
         }
         buffer.resize(bufferCapacity);

         size_t read = chunkers.last()->Read(&buffer[cur], bufferCapacity - cur);
         if (!read) {
            // No data read, break the loop
            delete chunkers.last();
            chunkers.pop_back();
            break;
         }
         cur += read;

         // Spawn off a thread to finish this chunk while we read another
         threads.push_back(0);
         pthread_create(&threads.last(), nullptr, ChunkerThread, chunkers.last());
      }

      for (size_t i = 0; i < threads.size(); i++)
         pthread_join(threads[i], nullptr);

      for (size_t i = 0; i < chunkers.size(); i++)
         delete chunkers[i];
   }

   static void *ChunkerThread(void *arg) {
      Chunker *chunker = (Chunker *)arg;
      chunker->Reverse();
      chunker->Print();
      return nullptr;
   }

protected:
   const char *data;
   size_t size;
};

int main(int argc, char *argv[]) {
   // Read the entire input into memory
   std::vector<char> inputData;
   char buffer[8192];
   size_t bytesRead;

   while ((bytesRead = fread(buffer, 1, sizeof(buffer), stdin)) > 0) {
      inputData.insert(inputData.end(), buffer, buffer + bytesRead);
   }
   size_t inputSize = inputData.size();

   int count = 1;
   if (argc > 1) {
      count = atoi(argv[1]);
      if (count <= 0)
         count = 1;
   }

   for (int counter = 0; counter < count; counter++) {
      // Clear stdout buffer to prevent mixing outputs from multiple iterations
      fflush(stdout);
      // Reset the static variable
      Chunker::printQueue = 0;

      start_rapl();
      ReverseComplement revcom(inputData.data(), inputSize);
      revcom.Run();
      stop_rapl();
   }

   return 0;
}
