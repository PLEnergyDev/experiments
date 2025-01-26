sudo docker run --rm \
  -v .:/experiments \
  -w /experiments/runtime-9.0.0 \
  -it \
  mcr.microsoft.com/dotnet-buildtools/prereqs:ubuntu-22.04
  # ./build.sh --subset clr