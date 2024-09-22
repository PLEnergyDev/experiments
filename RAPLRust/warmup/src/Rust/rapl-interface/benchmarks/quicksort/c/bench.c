#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void start_rapl();
void stop_rapl();

// helper function for removing characters from string
// https://stackoverflow.com/questions/5457608/how-to-remove-the-character-at-a-given-index-from-a-string-in-c
void RemoveChars(char *s, char c)
{
    int writer = 0, reader = 0;

    while (s[reader])
    {
        if (s[reader]!=c) 
        {   
            s[writer++] = s[reader];
        }

        reader++;       
    }

    s[writer]=0;
}

// helper function for counting characters
int countChar(char* str, char c){
    int i = 0; 
    for (i=0; str[i]; str[i]==c ? i++ : *str++);
    return i;
}

// helper function for converting string to array of int (comma seperated)
int* convertToIntArr(char* str, int len){
    int* arr = malloc(len * sizeof(int));
    char* token = strtok(str, ",");
    int i = 0;
    while (token != NULL) {
        arr[i] = atoi(token);
        token = strtok(NULL, ",");
        i++;
    }
    return arr;
}

// test function from Rosseta Code
void quicksort(int *A, int len) {
  if (len < 2) return;

  int pivot = A[len / 2];

  int i, j;
  for (i = 0, j = len - 1; ; i++, j--) {
    while (A[i] < pivot) i++;
    while (A[j] > pivot) j--;

    if (i >= j) break;

    int temp = A[i];
    A[i]     = A[j];
    A[j]     = temp;
  }

  quicksort(A, i);
  quicksort(A + i, len - i);
}

// function for reading file, inspired by https://stackoverflow.com/questions/3501338/c-read-file-line-by-line
char* readFile(char* path){
    FILE * fp;
    char * line = NULL; // the result
    size_t len = 0;
    size_t read;

    fp = fopen(path, "r");
    if (fp == NULL)
        exit(EXIT_FAILURE);
    
    while ((read = getline(&line, &len, fp)) != -1){
        // do nothing
    }

    fclose(fp);
    return line;
}

int main(int argc, char *argv[]) {    
    // getting raw input
    char* inputRaw = readFile(argv[2]);

    // removing brackets
    RemoveChars(inputRaw, '[');
    RemoveChars(inputRaw, ']');

    int sortParamLen = countChar(inputRaw,',') + 1;
    int* sortParam = convertToIntArr(inputRaw, sortParamLen);

    int count = atoi(argv[1]);

    // running benchmark
    for (int i = 0; i < count; i++) {
        // copying sortParam as quicksort is in-place
        int* sortParamCopy = malloc(sortParamLen * sizeof(int));
        for (int j = 0; j < sortParamLen; j++) {
            sortParamCopy[j] = sortParam[j];
        }

        start_rapl();

        quicksort(sortParamCopy, sortParamLen);

        stop_rapl();

        // stopping compiler optimization
        if (sortParamCopy[sortParamLen - 1] < 42){
            printf("%d\n", sortParamCopy[0]);
        }

        free(sortParamCopy);
    }

    free(sortParam);

    return 0;
}