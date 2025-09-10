#!/usr/bin/env bash
set -euo pipefail

FOLDER="./build/compiled"

for file in "$FOLDER"/*; do
  if [ -f "$file" ]; then
    echo "Signing: $file"
    gpg --local-user 79590A44041642E9 --detach-sign --armor -o "$file.sig" "$file"
  fi
done

echo "Done"
