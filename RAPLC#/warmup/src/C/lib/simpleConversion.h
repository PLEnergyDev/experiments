//
// Created by adrian on 10/18/22.
//
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#ifndef CSOCKETCOMM_SIMPLECONVERSION_H
#define CSOCKETCOMM_SIMPLECONVERSION_H
typedef int(*converter) (char*, void*, size_t);
typedef char*(*arrayConverter)(void*, size_t, int, int*);
void* byteToNumberGeneric(char* buf, size_t size);
int numberToByteGeneric(char* buffer, void* value, size_t size);
void* bytesToArrayGeneric(char* buffer, size_t size);
char* arrayToBytesGeneric(void* value, size_t element_size, int rank, int* dimensions);

#endif //CSOCKETCOMM_SIMPLECONVERSION_H
