import os
import csv
import subprocess
from concurrent.futures import ProcessPoolExecutor

# Parse params.txt to retrieve parameters
PARAMS_FILE = "./params.txt"
params = {}

with open(PARAMS_FILE, "r") as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith("#"):
            key, value = line.split("=", 1)
            params[key.strip()] = value.strip()

# Extract required parameters
ncores = int(params.get("ncores", 1))
GENE_LIST = "src/exclusion_list.txt"
INPUT_FILE = "results/raw.csv"
OUTPUT_FILE = "results/unfiltered.csv"
FILTERED_OUTPUT = "results/filtered.csv"

# Ensure required files exist
if not os.path.isfile(GENE_LIST):
    print(f"Gene list file not found: {GENE_LIST}")
    exit(1)

if not os.path.isfile(INPUT_FILE):
    print(f"Input file not found: {INPUT_FILE}")
    exit(1)

# Read the gene exclusion list
with open(GENE_LIST, "r") as f:
    exclude_genes = set(line.strip() for line in f)

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

# Step 2: Filter rows
print("Filtering out unwanted genes...")

with open(OUTPUT_FILE, "r", newline="") as infile, open(FILTERED_OUTPUT, "w", newline="") as outfile:
    reader = csv.DictReader(infile)
    writer = csv.DictWriter(outfile, fieldnames=reader.fieldnames)
    writer.writeheader()

    for row in reader:
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
os.remove(OUTPUT_FILE)
