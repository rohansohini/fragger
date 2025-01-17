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
wordsize=$(grep -oP '^wordsize=\K.*' "$PARAMS_FILE")
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
echo -e "seqid,sseqid,pident,length,mismatch,gapopen,sstart,send,qseq,sseq,evalue,bitscore" > "$OUTPUT_FILE"

for fasta_file in "$FASTA_DIR"/*.fasta; do
    echo "Processing $fasta_file..."

    # Run BLASTN
    echo "Running BLAST for $fasta_file with word_size $wordsize and e_val $eval..."
    blastn -db "$BLAST_DB" -query "$fasta_file" -word_size "$wordsize" -evalue "$eval" -num_threads "$ncores" -outfmt "10 qseqid sseqid pident length mismatch gapopen sstart send qseq sseq evalue bitscore" >> "$OUTPUT_FILE"
done

echo "All BLAST results have been written to $OUTPUT_FILE."

module purge all
