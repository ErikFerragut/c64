#!/bin/bash
# Build C64 tutorial in all formats

cd "$(dirname "$0")"

TITLE="C64 Assembly Tutorial"
RESOURCE_PATH="src:src/images"

echo "Building HTML..."
pandoc -s src/*.md \
  --resource-path="$RESOURCE_PATH" \
  -o out/c64-tutorial.html \
  --toc \
  --embed-resources --standalone \
  --metadata title="$TITLE"

echo "Building EPUB..."
pandoc -s src/*.md \
  --resource-path="$RESOURCE_PATH" \
  -o out/c64-tutorial.epub \
  --metadata title="$TITLE"

echo "Building PDF..."
pandoc -s src/*.md \
  --resource-path="$RESOURCE_PATH" \
  -o out/c64-tutorial.pdf \
  --pdf-engine=xelatex \
  --metadata title="$TITLE" \
  -V monofont="DejaVu Sans Mono"

echo "Done. Output in asm_tutorial/out/"
ls -lh out/
