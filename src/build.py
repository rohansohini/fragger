from functions import *

PARAMS_PATH = 'params.txt'
FASTA_DIR = 'fasta'
EXC_DIR = 'exclusion'
query_dict, ncores, organism = read_params(PARAMS_PATH)

for gene, content in query_dict.items():
    build_fasta(gene, organism, FASTA_DIR)
    _ = build_exclusion(gene, organism, content['excgene'], content['ppisize'], EXC_DIR)