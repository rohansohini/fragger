#!/bin/bash

module purge all
set -euo pipefail

# Paths
PARAMS_FILE="./params.txt"  # Path to the file containing parameters
EXC_DIR="exclusion"  # Path to the exclusion directory

# Initialize arrays to store parameters
genes=()
excgenes=()
ppisize=()

# Read the params.txt file line by line
while IFS= read -r line; do
  # Skip comment lines, empty lines, and the ncores line
  if [[ "$line" =~ ^# || -z "$line" || "$line" =~ ^ncores= ]]; then
    continue
  fi

  # Remove brackets and split the line into an array
  IFS=',' read -r -a params <<< "${line//[\[\]]}"

  # Append each parameter to its respective array
  genes+=("${params[0]}")
  excgenes+=("${params[5]}")
  ppisize+=("${params[6]}")
done < "$PARAMS_FILE"

# Ensure required directories exist
if [ ! -d "$EXC_DIR" ]; then
    echo "EXCLUSION directory does not exist. Creating it..."
    mkdir -p "$EXC_DIR" || { echo "Failed to create EXCLUSION directory! Exiting."; exit 1; }
fi

# Clear all previous exclusion files
rm -f "$EXC_DIR"/*.txt

# Step 1: Create EXCLUSION files using exclusion.pl
echo "Generating EXCLUSION files..."
for i in "${!genes[@]}"; do
    echo "Building exclusion list: ${genes[$i]}"
    perl "src/exclusion.pl" "${genes[$i]}" "${excgenes[$i]}" "${ppisize[$i]}" "${EXC_DIR}" || { echo "Error processing ${genes[$i]}! Exiting."; exit 1; }
done
