use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use POSIX qw(ceil);

# Set the number of fragments n
my $n = 50;

# Get the input gene symbol and output directory from the command line
my $gene_symbol = $ARGV[0];
my $output_dir = $ARGV[1];
die "Usage: $0 <gene_symbol> <output_dir>\n" unless defined $gene_symbol && defined $output_dir;

# Ensure the directory exists and ends with a slash
die "Output directory $output_dir does not exist!\n" unless -d $output_dir;
$output_dir .= "/" unless $output_dir =~ /\/$/;

my $http = HTTP::Tiny->new();

# Base Ensembl REST API server
my $server = 'https://rest.ensembl.org';

# Step 1: Fetch Ensembl ID for the gene symbol
my $ext1 = '/lookup/symbol/homo_sapiens/' . $gene_symbol . '?';
my $response1 = $http->get($server . $ext1, {
    headers => { 'Content-type' => 'application/json' }
});

die "Failed! Symbol->ID\n" unless $response1->{success};

my $id;
if (length $response1->{content}) {
    my $hash = decode_json($response1->{content});
    $id = $hash->{id};
}

# Step 2: Fetch the sequence using the Ensembl ID
my $ext2 = '/sequence/id/' . $id . '?';
my $response2 = $http->get($server . $ext2, {
    headers => { 'Content-type' => 'text/plain' }
});

die "Failed! ID->Sequence\n" unless $response2->{success};

my $sequence = $response2->{content};

# Validate the sequence
$sequence =~ s/[^ATCGN]//gi;

# Step 3: Split the sequence into x-bp to create n fragments
my $chunk_size = ceil(length($sequence) / $n);
my @fragments;
for (my $i = 0; $i < length($sequence); $i += $chunk_size) {
    push @fragments, substr($sequence, $i, $chunk_size);
}

# Step 4: Create a FASTA file with the fragments
my $output_file = $output_dir . "$gene_symbol.fasta";
if (-e $output_file) {
    warn "File $output_file already exists. Overwriting...\n";
}
open(my $fh, '>', $output_file) or die "Cannot open $output_file: $!\n";

my $fragment_number = 1;
foreach my $fragment (@fragments) {
    print $fh ">" . $gene_symbol . "_" . $fragment_number . "\n";
    print $fh $fragment . "\n";
    $fragment_number++;
}

close($fh);

print "FASTA file created: $output_file\n";
