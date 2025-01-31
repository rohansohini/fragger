#!/bin/bash

module purge all
set -euo pipefail

# Paths
PARAMS_FILE="./params.txt"  # Path to the file containing parameters
FASTA_DIR="fasta"  # Path to the fasta directory

# Clear all previous fasta files
rm -f "$FASTA_DIR"/*.fasta

# Initialize arrays to store parameters
genes=()
fmethods=()
fvals=()

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
  fmethods+=("${params[1]}")
  fvals+=("${params[2]}")
done < "$PARAMS_FILE"

# Ensure required directories exist
if [ ! -d "$FASTA_DIR" ]; then
    echo "FASTA directory does not exist. Creating it..."
    mkdir -p "$FASTA_DIR" || { echo "Failed to create FASTA directory! Exiting."; exit 1; }
fi

# Step 1: Create FASTA files using fragment.pl
echo "Generating FASTA files..."
for i in "${!genes[@]}"; do
    echo "Processing gene: ${genes[$i]}"
    perl "src/fragment.pl" "${genes[$i]}" "${fmethods[$i]}" "${fvals[$i]}" "${FASTA_DIR}"
done
