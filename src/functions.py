import os
import requests, sys
import pandas as pd
import numpy as np
import re
import json

def read_params(PARAMS_PATH):
    # open the parameters file
    file = open(PARAMS_PATH, 'r')

    query_dict = {}
    try:
        for line in file:
            # decode the parameters and store them in a dictionary of dictionaries (query_dict)
            if line.startswith('['):
                line = line.strip().strip('[]')
                [gene,wordsize,eval,excgene,ppisize] = line.split(',')
            
                query_dict[gene] = {'wordsize': int(wordsize.strip()),
                                    'eval':     float(eval.strip()),
                                    'excgene':  excgene.strip().lower() == 'true',
                                    'ppisize':  int(ppisize.strip())}

            # store the number of cores
            elif line.startswith('ncores='):
                ncores = int(line.split('=')[1].strip())

            # store the organism we are working with 
            elif line.startswith('organism'):
                organism = line.split('=')[1].strip().lower()
                if '_' not in organism: 
                    raise ValueError(f'error: orgnanism name "{organism}" must separate genus and species with an underscore (_).')

        # use the organism name to retieve the corresponding taxonomy ID from Ensembl API
        server = 'https://rest.ensembl.org'
        ext = f'/taxonomy/id/{organism}?'
    
        r = requests.get(server+ext, headers={ "Content-Type" : "application/json"})
        if not r.ok:
            print(f'error: could not retrieve Taxonomy ID for {organism}')
            r.raise_for_status()
            sys.exit()
    
        decoded = r.json()
        tax_id = int(decoded['id'].strip())
        organism = {'name': organism, 'tax_id': tax_id}

        return query_dict, ncores, organism   
                  
    except Exception as e:
        print('error: could not decode params.txt:\n' + str(e))

def retrieve_sequence(gene, organism):
    
    # use the gene symbol to retrieve the Ensembl ID from Ensembl API
    server = 'https://rest.ensembl.org'
    ext = f"/lookup/symbol/{organism['name']}/{gene}?"
 
    r = requests.get(server+ext, headers={ "Content-Type" : "application/json"})
 
    if not r.ok:
        print(f'error: could not find Ensembl ID for {gene}')
        r.raise_for_status()
        sys.exit()
 
    decoded = r.json()
    ens_id = decoded['id'].strip()

    # use the Ensembl ID to retrieve the gene sequence from Ensembl API
    ext = f'/sequence/id/{ens_id}?'
 
    r = requests.get(server+ext, headers={ "Content-Type" : "text/plain"})
 
    if not r.ok:
        print(f'error: could not retrieve sequence for {gene} with ID {ens_id}')
        r.raise_for_status()
        sys.exit()

    sequence = r.text.strip()

    return sequence

def build_fasta(gene, organism, FASTA_DIR):
    try:
        # check if provided FASTA_DIR exists, otherwise create
        isExist = os.path.exists(FASTA_DIR)

        if not isExist:
            os.makedirs(FASTA_DIR)
            print(f"fasta Folder '{FASTA_DIR}' created.")

        FASTA_PATH = os.path.join(FASTA_DIR, gene + '_' + organism['name'].replace('_', '') + '.fasta')

        # retrieve the sequence for the gene of interest
        sequence = retrieve_sequence(gene, organism)

        # write the sequence to a fasta file
        with open(FASTA_PATH, 'w') as fasta:
            fasta.write('>' + gene + '\n')
            fasta.write(sequence)
        
        print('fasta file: ' + gene + '_' + organism['name'].replace('_', '') + '.fasta ' + 'created')
        return
    
    except Exception as e:
        print(f'error: could not build fasta file for ' + gene + '\n' + str(e))

def retrieve_ppinetwork(gene, tax_id, ppisize):
    # use the gene symbol to retrieve the protein network from STRING-DB with the top {ppisize} number 
    # of predicted genes in the network
    server = 'https://string-db.org'
    ext = f'/api/json/interaction_partners?identifiers={gene}&limit={str(ppisize)}&species={str(tax_id)}'
 
    r = requests.get(server+ext)
 
    if not r.ok:
        print(f'error: could not retrieve Ensembl ID for {gene}')
        r.raise_for_status()
        sys.exit()
 
    network = r.json()

    proteins_in_network = []
    for protein in network:
        proteins_in_network.append(protein['preferredName_B'])
    return proteins_in_network

def build_exclusion(gene, organism, excgene, ppisize, EXC_DIR):
    try:
        # check if provided FASTA_DIR exists, otherwise create
        isExist = os.path.exists(EXC_DIR)
        
        if not isExist:
            os.makedirs(EXC_DIR)
            print(f"exclusion Folder '{EXC_DIR}' created.")

        EXC_PATH = os.path.join(EXC_DIR, gene + '_' + organism['name'].replace('_', '') + '.exc')

        # if the user does not want any filtering, leave the exclusion file blank
        if (excgene == False) and (ppisize == 0):
            with open(EXC_PATH, 'w') as exclusion:
                exclusion.write('')
            return
        
        proteins_in_network = retrieve_ppinetwork(gene, organism['tax_id'], ppisize)

        exc_list = []

        with open(EXC_PATH, 'w') as exclusion:
            # add the  gene of interest to list if excgene is True 
            # otherwise just add the genes from the protein netwrok
            if (excgene == True) & (len(proteins_in_network) == 0): exclusion.write(gene)
            elif (excgene == True): exclusion.write(gene + '\n') # only add new line if we will be adding ppi genes
            
            if excgene == True: exc_list.append(gene)

            exclusion.write('\n'.join(proteins_in_network)) # separate proteins with a newline character and write to file
        
        print('exclusion file: ' + gene + '_' + organism['name'].replace('_', '') + '.exc ' + 'created')

        return exc_list
    
    except Exception as e:
        print(f'error: could not build exclusion list for ' + gene + '\n' + str(e))

def gtf_to_df(gtf):
    # Read the GTF file into a pandas DataFrame, skipping comments
    df = pd.read_table(gtf, sep='\t', header=None, comment='#', dtype={0: str})
    
    # Set column names for the DataFrame
    df.columns = ['chr', 'source', 'type', 'start', 'end', 'score', 'strand', 'phase', 'extra']

    # Keep only HAVANA annotations
    #df = df[df['source'].str.lower() == 'havana']
    
    # Convert the chromosome column to numeric and drop rows with invalid chromosome values
    df.loc[:, 'chr'] = pd.to_numeric(df['chr'], errors='coerce')
    df.dropna(subset=['chr'], inplace=True)
    df['chr'] = df['chr'].astype('int64')

    # Define the regex pattern to extract relevant attributes from the 'extra' column
    pattern = r'(?:.*?gene_id "(.+?)")?(?:.*?transcript_id "(.+?)")?(?:.*?exon_number "(.+?)")?(?:.*?gene_name "(.+?)")?(?:.*?gene_biotype "(.+?)")?(?:.*?transcript_name "(.+?)")?(?:.*?transcript_biotype "(.+?)")?(?:.*?exon_id "(.+?)")?(?:.*?tag "(Ensembl_canonical)")?'
    
    # Apply the regex pattern and extract the relevant data
    extracted = df['extra'].str.extract(pattern)
    extracted.iloc[:, 8] = extracted.iloc[:, 8] == 'Ensembl_canonical'

    # Add the extracted data as new columns to the DataFrame
    df[['gene_id', 'transcript_id', 'exon_number', 'gene_name', 'gene_type', 'transcript_name', 'transcript_type', 'exon_id', 'canonical?']] = extracted
    # Drop the 'extra' column, as it's no longer needed
    df = df.drop('extra', axis=1)

    # Filter the DataFrame for 'protein_coding' genes and relevant region types (transcript, exon, CDS, UTR)
    condition1 = df['gene_type'] == 'protein_coding'
    condition2 = df['type'].isin(['gene', 'transcript', 'exon', 'CDS', 'UTR'])
    df = df[(condition2)]
    
    # Reset the DataFrame index after sorting
    df = df.sort_values(by=['chr', 'start', 'end'])
    df = df.reset_index(drop=True)

    # Clean up temporary variables
    del(pattern, condition1, condition2, extracted)

    return df

def process_annotations(df, exclusion):
    # initialize a dictionary to store transcript data and a set for unique gene names
    transcripts = {}
    gene_names = []
    primary_t_name = None
    primary_t_type = None

    # if there are no transcripts in the df, the coordinates likely belong to an intron, so we do not want to assign transcript information
    if len(df) == sum(df['type'] == 'gene'):
        for _, row in df.iterrows():
            if row['gene_name'] not in gene_names: gene_names.append(row["gene_name"])
        transcripts = None
        return gene_names_str, primary_t_name, primary_t_type, transcripts

    # remove any rows corresponding to the gene as a whole because we are interested in transcript information
    df = df[df.type != "gene"]    

    # iterate over each row in the filtered dataframe
    # 1) if it is the primary (canonical) transcript, assign it to the alloted variables
    # 2) assign all transcript info and format it using nested dictionaries
    for _, row in df.iterrows():
        t_name = row["transcript_name"]
        canon = row["canonical?"]

        if row["gene_name"] not in exclusion:

            if row["gene_name"] not in gene_names: gene_names.append(row["gene_name"])

            if canon == True:
                primary_t_name = t_name
                primary_t_type = row["transcript_type"]

            # create a new entry for the transcript if it doesn't already exist
            if t_name not in transcripts:
                transcripts[t_name] = {
                    "transcript_id": row["transcript_id"],
                    "transcript_type": row["transcript_type"],
                    "strand": row["strand"],
                    "regions": {}
                }

            # add region (exon, CDS, UTR) information to the transcript data
            region_type = row["type"]
            if pd.notna(row["exon_number"]):
                if region_type not in transcripts[t_name]["regions"]:
                    transcripts[t_name]["regions"][region_type] = []
                
                transcripts[t_name]["regions"][region_type].append(
                    {"exon_number": int(row["exon_number"]), "exon_id": row["transcript_id"]}
                )

    # convert the transcript data to json format
    transcripts = json.dumps(transcripts)
    # convert the set of unique gene names to a comma-separated string
    gene_names_str = ",".join(gene_names)

    if gene_names_str == '': gene_names_str = None
    if transcripts == '{}': transcripts = None

    return gene_names_str, primary_t_name, primary_t_type, transcripts

def search_annotation(df, chrom, start, end, exclusion):
    # filter the df using the given coordinates
    filtered = df[(df['chr'] == chrom) & (df['start'] < end) & (df['end'] > start)]
    
    # process the filtered annotations and return the results
    genes, primary_t_name, primary_t_type, transcript_info = process_annotations(filtered, exclusion)
    
    return genes, primary_t_name, primary_t_type, transcript_info