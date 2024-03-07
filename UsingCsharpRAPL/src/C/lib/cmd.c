#include "cmd.h"
#include<stdio.h>
#include<string.h>

char* UNKNOWN = "unknown";
char* ERROR = "error";
char* STOPPED = "stopped";
char* EXIT =  "exit";
char* GO = "go";
char* DONE = "done";
char* READY = "ready";
char* OK = "ok";
char* RECEIVE = "receive";

CMD parseCmd(char* cmd){
    printf("[%s]\n", cmd);
    if(0==strcmp(ERROR, cmd)) return Error;
    if(0==strcmp(STOPPED, cmd)) return Stopped;
    if(0==strcmp(EXIT, cmd)) return Exit;
    if(0==strcmp(GO, cmd)) return Go;
    if(0==strcmp(DONE, cmd)) return Done;
    if(0==strcmp(OK, cmd)) return Ok;
    if(0==strcmp(RECEIVE, cmd)) return Receive;

    // if(0==strcmp(Unknown, cmd)) 
        // return Unknown;
    return Unknown;
    
}
char* tos(CMD cmd){
    switch (cmd)
    {
        case Error:   return ERROR;
        case Stopped: return STOPPED;
        case Exit:    return EXIT;
        case Go:      return GO;
        case Done:    return DONE;
        case Ok:      return OK;
        case Ready:   return READY;
        case Receive: return RECEIVE;
        default:      return UNKNOWN;
    }
}