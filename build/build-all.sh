#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

mkdir -p build/compiled

TARGETS=(
  "x86_64-linux-gnu"
  "aarch64-linux-gnu"
  "x86_64-macos-none"
  "aarch64-macos-none"
  "x86_64-windows-gnu"
  "aarch64-windows-gnu"
)

echo -e "${CYAN}🏗 Starting Zig build process...${NC}"

for target in "${TARGETS[@]}"; do
  IFS='-' read -ra parts <<< "$target"
  OS="${parts[1]}"
  ARCH="${parts[0]}"
  EXT=""
  if [[ "$OS" == "windows" ]]; then
    EXT=".exe"
  fi
  
  OUTPUT="hello-${ARCH}-${OS}${EXT}"
  OUTPUT_PATH="build/compiled/${OUTPUT}"

  echo -e "${CYAN}🔧 Building for ${target}...${NC}"

  if ! zig build-exe main.zig \
    -target "$target" \
    -O ReleaseSmall \
    -femit-bin="$OUTPUT_PATH"; then
    echo -e "${RED}❌ Build failed for ${target}${NC}"
    exit 1
  fi
  
  if [[ "$OS" != "windows" ]]; then
    chmod +x "$OUTPUT_PATH"
  fi
done

echo -e "\n${GREEN}✅ All builds completed successfully!${NC}"
echo -e "${CYAN}Output files in ./build/compiled directory:${NC}"
ls -lh build/compiled
