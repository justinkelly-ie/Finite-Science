#!/bin/bash
set -e

# Load Emscripten environment
source ~/.emsdk/emsdk_env.sh

# Navigate to the Universe package
cd /var/home/justin/Projects/idris2-Universe

echo "Building Idris 2 C code..."
pack build idris2-LUniverse-wasm.ipkg

# The generated C file will be build/exec/luniverse_wasm.c
APP_C_FILE="build/exec/luniverse_wasm.c"

echo "Fetching Idris 2 v0.8.0 source for the WASM RTS..."
if [ ! -d "Idris2-0.8.0" ]; then
    curl -L https://github.com/idris-lang/Idris2/archive/refs/tags/v0.8.0.tar.gz | tar -xz
fi

# We must compile the RTS C files, our bridge.c, and the generated app C files into WASM
echo "Compiling WASM..."

# Note: This is a scaffold. We'll need to fine-tune the emcc flags, 
# handle GMP/BigInt if required by the Idris C backend, and include all RTS files.
emcc -O3 \
    -IIdris2-0.8.0/support/c \
    -IIdris2-0.8.0/support/refc \
    -s ASYNCIFY \
    -s EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
    -s EXPORTED_FUNCTIONS='["_alloc_request", "_trigger_compute", "_get_response", "_get_response_size"]' \
    Idris2-0.8.0/support/c/*.c \
    Idris2-0.8.0/support/refc/*.c \
    src/bridge.c \
    $APP_C_FILE \
    -o ../Nat-Science/visualizer/public/luniverse_wasm.js

echo "WASM compilation complete!"
