module purge all
module load blast

set -euo pipefail

# Paths
SRC_DIR="src"  # Path to the src directory
GENE_LIST="$SRC_DIR/genes.txt"  # Path to the file containing gene symbols
FASTA_DIR="fasta"  # Path to the fasta directory
RESULTS_DIR="results"  # Path to the results directory

# Determine BLAST_DB dynamically
BLAST_DB=$(ls ./blast_db/*.nto | sed 's/\.nto$//')

OUTPUT_FILE="$RESULTS_DIR/raw.csv"  # Combined BLAST output file

# Import parameters from params.txt
PARAMS_FILE="./params.txt"
eval=$(grep -oP '^eval=\K.*' "$PARAMS_FILE")
ncores=$(grep -oP '^ncores=\K.*' "$PARAMS_FILE")

# Ensure required directories exist
mkdir -p "$FASTA_DIR" "$RESULTS_DIR"

# Check if gene list file is provided
if [ -z "$GENE_LIST" ]; then
    echo "Usage: $0 <gene_list_file>"
    exit 1
fi

# Step 2: Run BLASTN on the generated FASTA files
echo "Running BLASTN..."

# Initialize the output file (overwrite if it exists) and add column names
echo -e "qseqid,tsseqid,tpident,tlength,tmismatch,tgapopen,tqstart,tqend,tsstart,tsend,tevalue,tbitscore" > "$OUTPUT_FILE"

for fasta_file in "$FASTA_DIR"/*.fasta; do
    echo "Processing $fasta_file..."

    # Extract the number of nucleotides in the first sequence entry
    FIRST_ENTRY_LENGTH=$(awk '/^>/ {if (NR > 1) exit} /^[^>]/ {seq = seq $0} END {print length(seq)}' "$fasta_file")
    if [ -z "$FIRST_ENTRY_LENGTH" ]; then
        echo "Error: Could not determine the length of the first entry in $fasta_file"
        continue
    fi

    # Calculate word size (ceiling of length/15)
    WORD_SIZE=$(( (FIRST_ENTRY_LENGTH + 14) / 15 ))
    echo "Calculated word_size for $fasta_file: $WORD_SIZE"

    # Run BLASTN
    echo "Running BLAST for $fasta_file with word_size $WORD_SIZE..."
    blastn -db "$BLAST_DB" -query "$fasta_file" -word_size "$WORD_SIZE" -evalue "$eval" -num_threads "$ncores" -outfmt "10 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore" >> "$OUTPUT_FILE"
done

echo "All BLAST results have been written to $OUTPUT_FILE."

module purge all
