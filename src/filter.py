import os
import csv
import subprocess
from concurrent.futures import ProcessPoolExecutor

# Parse params.txt to retrieve parameters
PARAMS_FILE = "./params.txt"
params = {}
genes = []

with open(PARAMS_FILE, "r") as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith("#"):
            if line.startswith("ncores="):
                # Extract ncores
                params["ncores"] = int(line.split("=")[1].strip())
            elif line.startswith("["):
                # Extract gene parameters
                gene_params = line.strip("[]").split(",")
                genes.append(gene_params[0].strip())  # Add gene to the genes vector

# Extract required parameters
ncores = params.get("ncores", 1)
INPUT_FILE = "results/raw.csv"
OUTPUT_FILE = "results/unfiltered.csv"
FILTERED_OUTPUT = "results/filtered.csv"
EXC_DIR = "exclusion"  # Directory containing gene-specific exclusion lists

# Ensure required files and directories exist
if not os.path.isfile(INPUT_FILE):
    print(f"Input file not found: {INPUT_FILE}")
    exit(1)

if not os.path.isdir(EXC_DIR):
    print(f"Exclusion directory not found: {EXC_DIR}")
    exit(1)

def get_exclusion_list(gene):
    """Get the exclusion list for a specific gene."""
    exc_file = os.path.join(EXC_DIR, f"exc{gene}.txt")
    if os.path.isfile(exc_file):
        with open(exc_file, "r") as f:
            return set(line.strip() for line in f)
    else:
        print(f"Exclusion list not found for gene: {gene}")
        return set()

def annotate_row(row):
    """Annotate a single row with gene information."""
    sseqid = row["sseqid"]
    sstart = int(row["sstart"])
    send = int(row["send"])

    try:
        chrom_ref = sseqid.split("|")[3]  # Extract e.g., NC_000001.11
        chrom_num = chrom_ref.replace("NC_", "").split(".")[0].lstrip("0")  # Remove 'NC_' and leading zeros
    except IndexError:
        chrom_num = ""

    start_coord, end_coord = (min(sstart, send), max(sstart, send))

    gene = ""
    if chrom_num and start_coord and end_coord:
        try:
            result = subprocess.run(
                ["perl", "src/mapcoords.pl", chrom_num, str(start_coord), str(end_coord)],
                capture_output=True,
                text=True,
                check=True,
            )
            gene = result.stdout.strip()
        except subprocess.CalledProcessError:
            gene = "error"

    row["gene"] = gene
    return row

# Step 1: Annotate rows in parallel
print("Annotating rows with genes in parallel...")

with open(INPUT_FILE, "r", newline="") as infile, open(OUTPUT_FILE, "w", newline="") as outfile:
    reader = csv.DictReader(infile)
    fieldnames = reader.fieldnames + ["gene"]
    writer = csv.DictWriter(outfile, fieldnames=fieldnames)
    writer.writeheader()

    with ProcessPoolExecutor(max_workers=ncores) as executor:
        annotated_rows = list(executor.map(annotate_row, reader))
        writer.writerows(annotated_rows)

# Step 2: Filter rows using gene-specific exclusion lists
print("Filtering out unwanted genes...")

with open(OUTPUT_FILE, "r", newline="") as infile, open(FILTERED_OUTPUT, "w", newline="") as outfile:
    reader = csv.DictReader(infile)
    writer = csv.DictWriter(outfile, fieldnames=reader.fieldnames)
    writer.writeheader()

    for row in reader:
        seqid = row["seqid"]
        gene_name = seqid.split("_")[0]  # Extract gene name from seqid (e.g., KLF6_0001 -> KLF6)

        # Get the exclusion list for the specific gene
        exclude_genes = get_exclusion_list(gene_name)

        gene_entry = row.get("gene", "").strip()
        if gene_entry:  # Check if the gene field is not empty
            genes = [gene.strip() for gene in gene_entry.split(",")]
            filtered_genes = [
                gene for gene in genes
                if gene.lower() != "error" and gene not in exclude_genes
            ]

            if filtered_genes:
                row["gene"] = ", ".join(filtered_genes)
                writer.writerow(row)

print(f"Filtered data written to {FILTERED_OUTPUT}.")

# Optionally, remove the intermediate file
#os.remove(OUTPUT_FILE)
