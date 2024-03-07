#!/bin/bash

LIBPATH="lib"

if [ $(which dotnet) == "" ]; then
    echo "[ERROR] dotnet not found! Please install dotnet to continue..."
    exit 1
fi 

echo "[INFO] Compiling... "
if test "$1" != "" ; then 
    echo "[INFO] Compiler options: $1..."
else
    echo "[INFO] No additional compiler options found..."
fi

dotnet restore $LIBPATH

dotnet build $1 $LIBPATH

if [ $? -eq 0 ]; then
    echo "[INFO] Build successful."
else
    echo "[ERROR] Build failed."
    exit 1
fi

echo -e "#!/bin/bash\n./lib/bin/Release/net8.0/linux-x64/lib \$1" > CsharpBench || exit 1

chmod +x CsharpBench || exit 1

echo "[INFO] Done!"
exit 0
