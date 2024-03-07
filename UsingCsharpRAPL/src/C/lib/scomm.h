#include "cmd.h"
#include "simpleConversion.h"
#include <stddef.h>
#ifndef SCOMM_H
#define SCOMM_H
void writeCmd(int socket, CMD cmd);
CMD readCmd(int socket);
int expectCmd(int socket, CMD cmd);
void sendValue(int socket, void* value, size_t size, converter);
void sendArray(int socket, void* value, size_t element_size, int rank, int* dimensions, arrayConverter con);
void* receiveValue(int socket, void*(*con)(char*, size_t), size_t size);
int connectTo(char *path);
int serveSingleClient(char *path);
int shakeHands(int socket);
int receiveHandshake(int socket);
void closeSocket(int socket);
int isLittleEndian();
void reverseArray(char* arr, size_t len);
#endif