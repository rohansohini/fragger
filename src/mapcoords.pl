#!/usr/bin/perl
use strict;
use warnings;
use HTTP::Tiny;
use JSON;

# Check for correct number of arguments
if (@ARGV != 3) {
    die "Usage: $0 <chromosome> <start_coord> <end_coord>\n";
}

# Get the arguments
my ($chromosome, $start, $end) = @ARGV;

# Initialize HTTP client
my $http = HTTP::Tiny->new();
my $server = 'https://rest.ensembl.org';
my $ext = "/overlap/region/human/$chromosome:$start-$end?feature=gene";

# Make the API request
my $response = $http->get($server . $ext, { headers => { 'Content-type' => 'application/json' } });

# Check if the request was successful
if (!$response->{success}) {
    print "error\n";
    exit 0;
}

# Parse the JSON response
my $genes;
eval {
    $genes = decode_json($response->{content});
};
if ($@ || !$genes || ref($genes) ne 'ARRAY') {
    print "error\n";
    exit 0;
}

# Check if any genes are returned
if (@$genes) {
    my @gene_names;

    foreach my $gene (@$genes) {
        # Include gene only if it is protein_coding
        if ($gene->{biotype} && $gene->{biotype} eq 'protein_coding') {
            push @gene_names, $gene->{external_name} || $gene->{id};
        }
    }

    # Print remaining gene names separated by commas
    print join(",", @gene_names) . "\n";
} else {
    print "\n";  # No genes found
}
