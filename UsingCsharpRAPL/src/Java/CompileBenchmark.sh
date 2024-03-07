#!/bin/bash

LIBPATH="lib"
OBJPATH="obj"

if [ $(which javac) == "" ]; then
    echo "[ERROR] javac not found! Please install javac to continue..."
    exit 1
fi 

if $(which java) == "" ]; then
    echo "[ERROR] java executable not found! Please add java to your path or provide a custom executable path..."
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

javac -g:none -d $OBJPATH $1 $LIBPATH/*.java
if [ $? -ne 0 ]; then
    echo "[ERROR] Compilation failed, exiting..."
    exit 1
fi

MANIFEST_FILE=$OBJPATH/MANIFEST.MF
echo "Main-Class: JavaIPC.Main" > $MANIFEST_FILE

JAR_FILE=$OBJPATH/JavaBench.jar
jar cfm $JAR_FILE $MANIFEST_FILE -C $OBJPATH .
if [ $? -ne 0 ]; then
    echo "[ERROR] JAR creation failed, exiting..."
    exit 1
fi

echo -e "#!/bin/bash\njava -jar $JAR_FILE \$1" > JavaBench || exit 1

chmod +x JavaBench || exit 1

echo "[INFO] Done!"
exit 0
