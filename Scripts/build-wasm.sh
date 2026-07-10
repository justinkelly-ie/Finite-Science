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

IDRIS_RTS_DIR="/var/home/justin/.cache/Idris2-0.8.0"
echo "Fetching Idris 2 v0.8.0 source for the WASM RTS..."
if [ ! -d "$IDRIS_RTS_DIR" ]; then
    mkdir -p "/var/home/justin/.cache"
    curl -L https://github.com/idris-lang/Idris2/archive/refs/tags/v0.8.0.tar.gz | tar -xz -C "/var/home/justin/.cache"
fi

# We must compile the RTS C files, our bridge.c, and the generated app C files into WASM
echo "Compiling WASM..."

# Note: This is a scaffold. We'll need to fine-tune the emcc flags, 
# handle GMP/BigInt if required by the Idris C backend, and include all RTS files.
emcc -O3 \
    -I"$IDRIS_RTS_DIR/support/c" \
    -I"$IDRIS_RTS_DIR/support/refc" \
    -s ASYNCIFY \
    -s EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
    -s EXPORTED_FUNCTIONS='["_alloc_request", "_trigger_compute", "_get_response", "_get_response_size"]' \
    "$IDRIS_RTS_DIR/support/c"/*.c \
    "$IDRIS_RTS_DIR/support/refc"/*.c \
    src/bridge.c \
    $APP_C_FILE \
    -o ../Finite-Science/visualizer/public/luniverse_wasm.js

echo "WASM compilation complete!"
