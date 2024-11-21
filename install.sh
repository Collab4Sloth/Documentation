
#!/bin/bash
set -e

cmake -S doc -B build -D CMAKE_INSTALL_PREFIX=$PWD

cmake --build build --target doc -- VERBOSE=1

cmake --install build -v