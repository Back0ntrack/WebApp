#!/bin/bash

# Check if the user has provided a domain name as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <domain_name>"
    exit 1
fi

# Set the target domain name
target=$1

# Create a directory to store the results if it doesn't exist
result_dir="./tools_results"
mkdir -p "$result_dir"

# Display the target domain
echo "Getting subdomains for: $target"

# Run FinalRecon and save the results
echo "Running FinalRecon..."
finalrecon --url "https://$target/" --sub > "$result_dir/final_recon_results.txt"

# Get CRT.sh results and save them
echo "Getting results from CRT.sh..."
curl -s "https://crt.sh/?q=${target}&output=json" | jq -r '.[] | "\(.name_value)\n\(.common_name)"' | sort -u | grep -w "$target" > "$result_dir/crt_sh_results.txt"

# Run Subfinder and save the results
echo "Running Subfinder..."
subfinder -d "$target" -o "$result_dir/subfinder_results.txt"

# Combine all results into one file, ensuring that duplicate subdomains are removed
echo "Combining results into one file..."
cat "$result_dir"/*.txt | sort -u | grep -w "$target" > "$result_dir/all_in_one_results.txt"

# Use httpx to verify the subdomains
echo "Verifying subdomains with httpx..."
~/go/bin/httpx -l "$result_dir/all_in_one_results.txt" -o "$result_dir/httpx_verified_results.txt"

# Display a message indicating that the process is complete
echo "Subdomain enumeration completed."
echo "Results saved in: $result_dir"
