use strict;
use warnings;
use HTTP::Tiny;
use JSON;

# Get the input gene symbol and output directory from the command line
my $gene = $ARGV[0];
my $fmethod = $ARGV[1];
my $fval = $ARGV[2];
my $FASTA_DIR = $ARGV[3];

die "Usage: $0 <gene_symbol> <fmethod> <fval> <output_dir>\n"
    unless defined $gene && defined $fmethod && defined $fval && defined $FASTA_DIR;

# Ensure the directory exists and ends with a slash
die "Output directory $FASTA_DIR does not exist!\n" unless -d $FASTA_DIR;
$FASTA_DIR .= "/" unless $FASTA_DIR =~ /\/$/;

my $http = HTTP::Tiny->new();

# Base Ensembl REST API server
my $server = 'https://rest.ensembl.org';

# Step 1: Fetch Ensembl ID for the gene symbol
my $ext1 = '/lookup/symbol/homo_sapiens/' . $gene . '?';
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

# Step 3: Split the sequence based on the fragmentation method
my @fragments;
if ($fmethod eq 'nfrag') {
    # Split the sequence into $fval number of fragments
    my $fragment_length = int(length($sequence) / $fval);
    my $remainder = length($sequence) % $fval;

    for (my $i = 0; $i < length($sequence); $i += $fragment_length) {
        my $length = $fragment_length;
        # Add the remainder to the last fragment
        if ($i + $fragment_length >= length($sequence) - $remainder) {
            $length += $remainder;
        }
        push @fragments, substr($sequence, $i, $length);
    }
} elsif ($fmethod eq 'fragsize') {
    # Split the sequence into fragments of size $fval
    for (my $i = 0; $i < length($sequence); $i += $fval) {
        push @fragments, substr($sequence, $i, $fval);
    }
} else {
    die "Invalid fragmentation method: $fmethod. Use 'nfrag' or 'fragsize'.\n";
}

# Step 4: Create a FASTA file with the fragments
my $output_file = $FASTA_DIR . "$gene.fasta";
if (-e $output_file) {
    warn "File $output_file already exists. Overwriting...\n";
}
open(my $fh, '>', $output_file) or die "Cannot open $output_file: $!\n";

my $fragment_number = 1;
foreach my $fragment (@fragments) {
    my $padded_number = sprintf("%04d", $fragment_number);
    print $fh ">" . $gene . "_" . $padded_number . "\n";
    print $fh $fragment . "\n";
    $fragment_number++;
}

close($fh);

print "FASTA file created: $output_file\n";
