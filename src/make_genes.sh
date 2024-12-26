#!/bin/bash

set -euo pipefail

# Path to params.txt
PARAMS_FILE="./params.txt"

# Path to output gene list
GENE_LIST_FILE="src/genes.txt"

# Ensure the output directory exists
mkdir -p "$(dirname "$GENE_LIST_FILE")"

# Extract genes from params.txt
genes=$(grep -oP '^genes=\K.*' "$PARAMS_FILE")

# Check if genes are specified
if [ -z "$genes" ]; then
    echo "Error: No genes specified in $PARAMS_FILE."
    exit 1
fi

# Write genes to the output file, one per line
echo "$genes" | tr ',' '\n' > "$GENE_LIST_FILE"

echo "Gene list has been written to $GENE_LIST_FILE."
