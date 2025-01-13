#!/bin/bash
set -e
# Script to run all .sh files in the 'scripts' folder with and without 'arm64' argument
# Create directories if they don't exist
mkdir -p amd64 arm64
for script in scripts/*.sh; do
    if [[ -f "$script" ]]; then
        # Run the script with no arguments
        echo "Running $script for amd64"
        bash "$script"
        
        # Run the script with 'arm64' argument
        echo "Running $script for arm64"
        bash "$script" arm64
    fi
done
directories=("amd64" "arm64")
echo "All scripts have been executed."
echo "Generating checksums" 
for dir in "${directories[@]}"; do
  for file in "$dir"/*; do
    if [ -f "$file" ] && [[ "$file" != *.txt ]]; then
      # Generate the checksum and save it to [file]_checksum.txt
      sha256sum "$file" > "$file"_checksum.txt
    fi
  done
done
echo "all finished"