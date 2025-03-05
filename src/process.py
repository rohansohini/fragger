import os
import sys
import pandas as pd
import numpy as np
import multiprocessing as mp
from functions import *

def process_row(row):
    try:
        gene_name = row['seqid']
        sseqid = row["sseqid"]

        chrom_ref = sseqid.split("|")[3]
        chrom_num = int(chrom_ref.replace("NC_", "").split(".")[0].lstrip("0").strip())
        
        sstart = int(row["sstart"])
        send = int(row["send"])
        start_coord, end_coord = min(sstart, send), max(sstart, send)
        
        # Use global variables set by pool initializer
        search_result = search_annotation(
            df=gtf,
            chrom=chrom_num,
            start=start_coord,
            end=end_coord,
            exclusion=exclusion[gene_name]
        )

        if not search_result:
            return (np.nan, np.nan, np.nan, np.nan)
            
        genes, primary_t_name, primary_t_type, transcript_info = search_result
        
        output_gene = genes if genes else np.nan
        primary_t_name = primary_t_name if primary_t_name else np.nan
        primary_t_type = primary_t_type if primary_t_type else np.nan
        transcript_info = transcript_info if transcript_info else np.nan
        
    except Exception as e:
        return (np.nan, np.nan, np.nan, np.nan)

    return (output_gene, primary_t_name, primary_t_type, transcript_info)

def init_pool(exclusion_, gtf_):
    global exclusion, gtf
    exclusion = exclusion_
    gtf = gtf_

if __name__ == '__main__':
    # Read parameters and setup data
    query_dict, ncores, organism = read_params('params.txt')
    
    exclusion = {}
    for gene, content in query_dict.items():
        exclusion[gene] = build_exclusion(gene, organism, content['excgene'], 
                                        content['ppisize'], "exclusion")

    gtf = gtf_to_df(
    next(
        (os.path.join("annotation", f) 
        for f in os.listdir("annotation") 
        if f.endswith(".gtf")
    ), None))

    # Read raw data
    raw = pd.read_csv('results/raw.csv')
    rows = raw.to_dict('records')

    # Process rows in parallel
    with mp.Pool(processes=ncores, initializer=init_pool, initargs=(exclusion, gtf)) as pool:
        results = pool.map(process_row, rows)

    # Combine results with original DataFrame
    result_df = pd.DataFrame(results, columns=['gene', 'primary_t_name', 
                                             'primary_t_type', 'transcript_info'])
    raw[['gene', 'primary_t_name', 'primary_t_type', 'transcript_info']] = result_df

    # Clean and save results
    raw.dropna(subset=['gene'], inplace=True)
    raw.to_csv('results/processed.csv', index=False)