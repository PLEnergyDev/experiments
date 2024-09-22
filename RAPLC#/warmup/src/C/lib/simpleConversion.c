//
// Created by adrian on 10/18/22.
//
#include "scomm.h"
#include "simpleConversion.h"
#include <stddef.h>
#include <stdio.h>

/// Converts a byte array as char* to a void pointer that can be cast to a number type
/// \param buf char* containing the byte array to be converted, assumes big-endian
/// \param size the size in bytes of the desired result
/// \return void* to the result
void* byteToNumberGeneric(char* buf, size_t size){
    void* result = malloc(size);
    if(isLittleEndian())
        reverseArray(buf, size);
    memcpy(result, buf, size);
    return result;
}

/// Converts a void* containing a single numeric value into a char* containing a byte array representing the value
/// \param value a void* to the value
/// \param size the size of the value
/// \return a char* containing the byte array representing the value, big-endian
int numberToByteGeneric(char* buffer, void* value, size_t size){
    memcpy(buffer, value, size);
    if(isLittleEndian())
        reverseArray(buffer, size);
    return size;
}


/// Convert an array of single numeric values into a char* containing a byte array representing the array.
/// Assumes a row-first array layout. Single values will be big-endian.
/// \param array void* containing array to be converted
/// \param element_size size of each element in the array
/// \param rank the rank (number of dimensions) of the array
/// \param dimensions an int array of size rank containing the size of each dimension
/// \return a char* containing [rank, dimension sizes, values] big-endian
char* arrayToBytesGeneric(void* value, size_t element_size, int rank, int* dimensions) {
    int result_size = 0;
    result_size += sizeof(int) * (rank + 1);
    int elements = 1;
    for (int i = 0; i < rank; i++) {
        elements *= dimensions[i];
    }
    result_size += elements * element_size;
    char* buffer = malloc(result_size);
    int offset = 0;
    // Put rank
    memcpy(buffer, &rank, sizeof(int));
    if(isLittleEndian()){
        reverseArray(buffer+offset, sizeof(int));
    }
    offset += sizeof(int);

    // Put dimensions
    memcpy(buffer + offset, dimensions, sizeof(int) * rank);
    if(isLittleEndian()){
        for(int i = 0; i < rank; i++){
            reverseArray(buffer+offset + (i * sizeof(int)), sizeof(int));
        }
    }

    offset += sizeof(int) * rank;

    // Put values
    memcpy(buffer + offset, value, element_size * elements);
    if(isLittleEndian()){
        for(int i = 0; i < elements; i++){
            reverseArray(buffer + offset + (i * element_size), element_size);
        }
    }
    return buffer;
}


void* bytesToArrayGeneric(char* buffer, size_t size){
    int offset = 0;
    int rank = 0;
    printf("%s\n", buffer);
    //Get rank
    memcpy(&rank, buffer, sizeof(int));
    if(isLittleEndian()){
        reverseArray((char*)&rank, sizeof(int));
    }
    offset += sizeof(int);
    printf("Rank is %d\n", rank);

    // Get dimensions
    int* dimension = malloc(rank * sizeof(int));
    memcpy(dimension, buffer + offset, sizeof(int) * rank);
    offset += sizeof(int) * rank;
    if(isLittleEndian()){
        for(int i = 0; i < rank; i++){
            reverseArray((char*)dimension + (i * sizeof(int)), sizeof(int));

        }
    }


    // Get values
    int result_size = 1;
    for(int i = 0; i < rank; i++){
        result_size *= dimension[i];
    }
    void* result = malloc(result_size * size);
    memcpy(result, buffer + offset, result_size * size);
    if(isLittleEndian()){
        for(int i = 0; i < result_size; i++){
            reverseArray(result + (i * size), size);
        }
    }

    return result;
}