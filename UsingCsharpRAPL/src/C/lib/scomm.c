#include<stdio.h>
#include<stdlib.h>
#include<sys/socket.h>
#include<sys/un.h>
#include<unistd.h>
#include "cmd.h"
#include "scomm.h"
#include "simpleConversion.h"

void reverseArray(char* arr, size_t len){
    for(int i = 0; i < len / 2; i++) {
        char temp = arr[i];
        arr[i] = arr[len - i - 1];
        arr[len - i - 1] = temp;
    }
}

int byteToInt(char* buf, size_t size){
    int* result = malloc(size);
    if(isLittleEndian())
        reverseArray(buf, size);
    memcpy(result, buf, size);
    int res = *(result);
    free(result);
    return res;
}

char* intToByte(int value){
    int size = sizeof(int);
    char* buf = malloc(size);
    memcpy(buf, &value, size);
    if(isLittleEndian())
        reverseArray(buf, size);
    return buf;
}

void writeCmd(int socket, CMD cmd){
    printf("Writecmd: ");
    printf("ch: %s\n", tos(cmd));
    if (write(socket, (char*)&cmd, 1) < 0) {
        perror("error writing to socket");
    }
}

CMD readCmd(int socket){
    char ch;
    printf("Readcmd: ");
    int bytes_read = read(socket, &ch, sizeof(char));
    printf("bytesread: %d -- ", bytes_read);
    printf("ch: %s\n", tos(ch));
    return (CMD)ch;
}

int expectCmd(int socket, CMD cmd){
    CMD read = readCmd(socket);
    if(read == cmd){
        return 1;
    }
    fprintf(stderr,"Error: Expected: %d - Received: %d\n", cmd, read);
    return 0;
}

void sendValue(int socket, void* value, size_t size, converter con){
    writeCmd(socket, Receive);
    expectCmd(socket,Ready);
    char* buf = malloc(size);
    int sendSize = con(buf, value, size);
    printf("Sending: %d bytes \n", sendSize);
    char* lenbuf = intToByte(sendSize);
    write(socket, lenbuf, 4);
    write(socket, buf, sendSize);
    expectCmd(socket, Ok);
    free(lenbuf);
    free(buf);
}

void sendArray(int socket, void* value, size_t element_size, int rank, int* dimensions, arrayConverter con){
    writeCmd(socket, Receive);
    expectCmd(socket,Ready);
    //Calculate array size
    int sendSize = 1;
    for(int i = 0; i < rank; i++){
        sendSize *= dimensions[i];
    }
    sendSize *= element_size;
    sendSize += (rank + 1) * sizeof(int);

    char* buf = con(value, element_size, rank, dimensions);
    /*printf("Sending: %d bytes \n", sendSize);
    printf("Value: " );
    for(int i = 0; i < sendSize; i++){
        printf("\\%02hhx", buf[i]);
    }
    printf("\n");*/
    char* lenbuf = intToByte(sendSize);
    write(socket, lenbuf, 4);
    write(socket, buf, sendSize);
    expectCmd(socket, Ok);
    free(lenbuf);
    free(buf);
}

void* receiveValue(int socket, void*(*con)(char*, size_t), size_t size){
    writeCmd(socket, Ready);
    char* buf = malloc(4 * sizeof(char));
    read(socket, buf, 4);
    int length = byteToInt(buf, 4);
    printf("Receiving %d bytes!\n", length);
    buf = malloc(length * sizeof(char));
    read(socket, buf, length);
    /*for(int i = 0; i < length; i++){
        printf("\\%02hhx", buf[i]);
    }
    printf("\n");*/
    void* result = con(buf, size);
    writeCmd(socket, Ok);
    free(buf);
    return result;
}

void closeSocket(int socket){
    close(socket);
}


struct sockaddr_un unix_sa(char *path){
    struct sockaddr_un address;
    memset(&address, 0, sizeof(address));
    strcpy(address.sun_path, path);
    address.sun_family = AF_UNIX;
    return address;
}

int unixsock(){
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if(fd <0){
        perror("socket failed");
        return -1;
    }
    return fd;
}

void rev(char *buf, int l){
    int n=l/2;
    for(int i=0;i<n;i++){
        char t = buf[i];
        buf[i]=buf[(l-i)-1];
        buf[(l-i)-1]=t;
    }
}

int serveSingleClient(char *path){
    if( access( path, F_OK ) >= 0)
    {
        fprintf(stderr,"File already exists: (%s)\n", path);
        return -1;
    }
    struct sockaddr_un address = unix_sa(path);
    int listensocket = unixsock();
    if( bind(listensocket, (struct sockaddr*)(&address), sizeof(struct sockaddr_un)) <0){
        perror("Bind failed");
        return -1;
    }
    if(listen(listensocket, 1)<0){
        perror("Listen failed");
        return -1;
    }
    socklen_t size = sizeof(struct sockaddr_un);
    int clientSocket = accept(listensocket, (struct sockaddr*)(&address), &size);
    close(listensocket);
    remove(path);
    if(receiveHandshake(clientSocket)<0){
        fprintf(stderr, "Bad handshake...\n");
        return -1;
    }
    return clientSocket;
}

int connectTo(char *path){
    if( access( path, F_OK ) < 0)
    {
        fprintf(stderr,"File does not exists: (%s)\n", path);
        return -1;
    }
    struct sockaddr_un address = unix_sa(path);
    int socket = unixsock();
    if (connect(socket, (struct sockaddr*)&address, sizeof(struct sockaddr_un)) < 0) {
        perror("Connection Failed");
        return -1;
    }
    if(shakeHands(socket)<0){
        fprintf(stderr, "Bad handsake...\n");
        return -1;
    }
    return socket;
}

int receiveHandshake(int socket){
    int32_t k;
    int32_t hsValue = 25;
    char* buffer = malloc(4);
    if(4!=read(socket, buffer, sizeof(int32_t))){
        printf("Error receiving handshake");
        return -2;
    }
    if(isLittleEndian()){
        reverseArray(buffer, 4);
    }
    memcpy(&k, buffer, 4);
    if(hsValue!=k){
        printf("Bad handshake response: %d\n", k);
        return -3;
    }
    if(isLittleEndian()){
        reverseArray(buffer,4);
    }
    if(4!=write(socket, buffer, sizeof(int32_t))){
        printf("Error replying handshake!");
        return -1;
    }
}

int shakeHands(int socket){
    printf("shaking hands");
    int32_t k = 25;
    int32_t result;
    char* buffer = malloc(4);
    memcpy(buffer, &k, 4);
    if(isLittleEndian()){
        reverseArray(buffer, 4);
    }
    if(4!=write(socket, buffer, sizeof(int32_t))){
        printf("Error initializing handshake!");
        return -1;
    }
    if(4!=read(socket, buffer, sizeof(int32_t))){
        printf("Error receiving handshake");
        return -2;
    }
    if(isLittleEndian()){
        reverseArray(buffer, 4);
    }
    memcpy(&result, buffer, 4);

    if(result!=k){
        printf("Bad handshake response: %d\n", result);
        return -3;
    }
    printf("...\n");
    return 0;
}

int isLittleEndian(){
    int x = 1;
    char *y = (char*)&x;
    return (int)*y;
}