#!/bin/bash

VIDEO_URL=$1
OUT_DIR=$2

# 1. Validation
if [[ -z "$VIDEO_URL" || -z "$OUT_DIR" ]]; then
    echo "Usage: $0 <URL> <output_directory>"
    exit 1
fi

mkdir -p "$OUT_DIR"

# 2. Download (using Deno as your runtime)
yt-dlp --js-runtimes deno --remote-components ejs:github \
       --write-auto-subs --sub-lang "en.*" --skip-download \
       --no-playlist \
       --output "$OUT_DIR/%(title)s.%(ext)s" "$VIDEO_URL"

# 3. Clean-up (scoped to the directory you provided)
# This removes timestamps, HTML-like tags, and consecutive duplicate lines
find "$OUT_DIR" -name "*.vtt" -exec sed -i 's/<[^>]*>//g' {} +
find "$OUT_DIR" -name "*.vtt" -exec sed -i 'N;/\(.*\)\n\1$/!P;D' {} +

echo "Success! Transcripts cleaned and saved in: $OUT_DIR"
