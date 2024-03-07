#!/bin/bash

LIBPATH="lib"
OBJPATH="obj"

if [ $(which gcc) == "" ]; then
    echo "[ERROR] gcc not found! Please install gcc to continue..."
    exit 1
fi 

echo "[INFO] Compiling... "
if test "$1" != "" ; then 
    echo "[INFO] Compiler options: $1..."
else
    echo "[INFO] No additional compiler options found..."
fi

if [ ! -d $OBJPATH ]; then
    mkdir -p $OBJPATH || exit 1
fi

for file in $LIBPATH/*.c; do
    if [ $(basename $file) = "main.c" ]; then
        continue
    fi

    gcc -c $file -o $OBJPATH/$(basename ${file%.c}).o -O3 || exit 1
done

ar rcs $OBJPATH/libcomponents.a $OBJPATH/*.o || exit 1

gcc $LIBPATH/main.c -o CBench -L$OBJPATH -lcomponents $1 || exit 1

echo "[INFO] Done!"
exit 0
