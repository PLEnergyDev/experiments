#include <sys/un.h>
#include <sys/socket.h>

#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <unistd.h>

#include "scomm.h"
#include "cmd.h"

///[INCLUDES]

int main(int argc, char **argv) {
    if(argc <= 1) {
        fprintf(stderr,"\nUsage: %s [socket]\n\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    char* pipe = argv[1];
    int LoopIterations = 1;
    int s = connectTo(pipe);
    if(s < 0) {
        printf("Bad socket...");
        exit(EXIT_FAILURE);
    }
    writeCmd(s, Ready);

    int c;
    do {
        writeCmd(s, Ready);
        if(expectCmd(s, Go)) {
            for(int i = 0; i < LoopIterations; i++) {
                ///[BENCHMARK]
            }
        } else {
            exit(EXIT_FAILURE);
        }
        ///[RESULT]
        writeCmd(s, Done);
        c = readCmd(s);
    } while(c == Ready);
    // we should have read done at this point
    printf("\ndone\n");
    closeSocket(s);
}
