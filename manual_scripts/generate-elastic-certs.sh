#!/bin/bash

###############################################################################
# Default Configuration
###############################################################################
VAULT_ADDR=${VAULT_ADDR:-"https://192.168.86.21:8200"}
PKI_ENGINE="pki-root-ca"
ROLE_NAME="generic"
TTL="8760h"  # 1 year
CERTS_BASE_DIR="./elastic-certs"

###############################################################################
# Colors for Output
###############################################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

###############################################################################
# Prerequisite Checks
###############################################################################
if ! command -v vault &> /dev/null; then
    echo -e "${RED}Error: vault command not found${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq command not found${NC}"
    exit 1
fi

###############################################################################
# Utility Functions
###############################################################################

# Flush any leftover stdin so we have a clean prompt
flush_stdin() {
  # Keep reading until there's no data left
  while read -r -t 0.001 _unused_; do :; done
}

# Validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r a b c d <<< "$ip"
        for part in "$a" "$b" "$c" "$d"; do
            if (( part < 0 || part > 255 )); then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Read multi-line input and return comma-separated values
# - input_type = "ip": validate each line as an IP
# - input_type = "dns": no validation
read_multiline() {
    local input_type=$1
    local -a lines=()
    local line=""

    echo "Enter one $input_type value per line; press ENTER on an empty line to finish:"
    while true; do
        # Prompt without color codes to avoid capturing them as input
        read -r -p "> " line

        # If the user presses ENTER on an empty line, we stop
        if [[ -z "$line" ]]; then
            break
        fi
        
        # Validate if we're collecting IP addresses
        if [[ "$input_type" == "ip" ]]; then
            if ! validate_ip "$line"; then
                echo -e "${RED}Invalid IP address: $line${NC}"
                continue
            fi
        fi
        
        # Accumulate into an array
        lines+=( "$line" )
    done
    
    # Join array elements with commas
    local joined
    IFS=',' read -r -a joined <<< "${lines[*]}"
    (IFS=','; echo "${lines[*]}")
}

###############################################################################
# Main Script
###############################################################################

# Prompt for common name
while true; do
    echo -e "${YELLOW}Enter the common name (e.g., ns-elastic-01.local):${NC}"
    read -r common_name
    if [[ -n "$common_name" ]]; then
        break
    fi
    echo -e "${RED}Common name cannot be empty${NC}"
done

# Prompt for short name (http|transport)
while true; do
    echo -e "${YELLOW}Enter a short name for the certificate type (e.g., http, transport):${NC}"
    read -r short_name
    if [[ "$short_name" =~ ^(http|transport)$ ]]; then
        break
    fi
    echo -e "${RED}Short name must be either 'http' or 'transport'${NC}"
done

# Flush any extra newlines in stdin
flush_stdin

# Prompt for IP SANs
echo -e "${YELLOW}Collecting IP SANs...${NC}"
ip_sans=$(read_multiline "ip")

flush_stdin

# Prompt for DNS SANs
echo -e "${YELLOW}Collecting DNS SANs...${NC}"
sans=$(read_multiline "dns")

# Create output directory
cert_dir="$CERTS_BASE_DIR/$common_name"
mkdir -p "$cert_dir"

# Generate certificates via Vault
echo -e "${GREEN}Generating certificates...${NC}"
echo -e "${YELLOW}Executing Vault command:${NC}"
echo -e "vault write -format=json $PKI_ENGINE/issue/$ROLE_NAME \\"
echo -e "  common_name=\"$common_name\" \\"
echo -e "  alt_names=\"$sans\" \\"
echo -e "  ip_sans=\"$ip_sans\" \\"
echo -e "  ttl=\"$TTL\""

cert_data=$(vault write -format=json "$PKI_ENGINE/issue/$ROLE_NAME" \
    common_name="$common_name" \
    alt_names="$sans" \
    ip_sans="$ip_sans" \
    ttl="$TTL")

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Certificate generation failed${NC}"
    exit 1
fi

# Extract and save certificates
echo "$cert_data" | jq -r '.data.private_key'   > "$cert_dir/${short_name}.key"
echo "$cert_data" | jq -r '.data.certificate'   > "$cert_dir/${short_name}.pem"
echo "$cert_data" | jq -r '.data.issuing_ca'    > "$cert_dir/${short_name}-ca.pem"
echo "$cert_data" | jq -r '.data.ca_chain[]'    > "$cert_dir/${short_name}-chain.pem"

chmod 600 "$cert_dir"/*

echo -e "${GREEN}Certificates generated successfully in $cert_dir${NC}"
echo -e "${GREEN}Files generated:${NC}"
ls -l "$cert_dir"
