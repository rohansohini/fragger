use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use File::Spec;

# Path to the parameter file
my $param_file = './params.txt';

# Function to parse the parameter file
sub parse_params {
    my ($file) = @_;
    my %params;

    open my $fh, '<', $file or die "Could not open $file: $!";
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*#/;  # Skip comments
        next if $line =~ /^\s*$/; # Skip empty lines

        if ($line =~ /^([^=]+)=(.+)$/) {
            my ($key, $value) = ($1, $2);
            $key =~ s/^\s+|\s+$//g;
            $value =~ s/^\s+|\s+$//g;
            $params{$key} = $value;
        }
    }
    close $fh;

    return %params;
}

# Parse parameters from the file
my %params = parse_params($param_file);

# Extract the limit from the parameters (default to 10 if not specified)
my $limit = $params{limit} // 10;

# Define the API URL
my $api_url = "https://string-db.org/api/json/interaction_partners";

# Input and output files
my $input_file = "src/genes.txt";
my $output_file = "src/exclusion_list.txt";

# Read genes from the input file
open my $in_fh, '<', $input_file or die "Could not open $input_file: $!";
my @genes = map { chomp; $_ } <$in_fh>;
close $in_fh;

# Create an HTTP::Tiny instance
my $http = HTTP::Tiny->new;

# Open the output file for writing
open my $out_fh, '>', $output_file or die "Could not open $output_file: $!";

# Process each gene
foreach my $gene (@genes) {
    # Construct the full URL with query parameters
    my $full_url = "$api_url?identifiers=$gene&limit=$limit";

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
}

# Ensure the genes from the input file are also in the exclusion list
foreach my $gene (@genes) {
    print $out_fh "$gene\n";
}

# Close the output file
close $out_fh or die "Could not close $output_file: $!";

# Print success message
print "Data processing completed successfully. Results saved to $output_file.\n";
