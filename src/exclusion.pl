use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use File::Spec;

# Get inputs from command line
my ($gene, $excgene, $ppisize, $exc_dir) = @ARGV;

# Validate inputs
die "Usage: $0 <gene> <excgene> <ppisize> <exc_dir>\n"
    unless defined $gene && defined $excgene && defined $ppisize && defined $exc_dir;

# Ensure the output directory exists
unless (-d $exc_dir) {
    die "Output directory $exc_dir does not exist!\n";
}

# Define the API URL
my $api_url = "https://string-db.org/api/json/interaction_partners";

# Create an HTTP::Tiny instance
my $http = HTTP::Tiny->new;

# Output file path
my $output_file = File::Spec->catfile($exc_dir, "exc$gene.txt");

# Open the output file for writing
open my $out_fh, '>', $output_file or die "Could not open $output_file: $!\n";

# Add the gene itself to the exclusion list if excgene is true
if ($excgene eq 'true') {
    print $out_fh "$gene\n";
}

# Construct the full URL with query parameters
my $full_url = "$api_url?identifiers=$gene&limit=$ppisize";

# Make the GET request
my $response = $http->get($full_url);

# Check if the request was successful
if ($response->{success}) {
    # Decode the JSON response
    my $data = decode_json($response->{content});

    # Extract and write preferredName_B to the output file
    foreach my $interaction (@$data) {
        print $out_fh "$interaction->{preferredName_B}\n";
    }
} else {
    # Print an error message for the specific gene
    warn "Failed to fetch data for $gene: $response->{status} $response->{reason}\n";
}

# Close the output file
close $out_fh or die "Could not close $output_file: $!\n";

# Print success message
print "Exclusion list for $gene created successfully: $output_file\n";
