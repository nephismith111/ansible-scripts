#!/bin/bash

# Default configuration
VAULT_ADDR=${VAULT_ADDR:-"https://vault.local:8200"}
PKI_ENGINE="pki-root-ca"
ROLE_NAME="generic"
TTL="8760h"  # 1 year
CERTS_BASE_DIR="./elastic-certs"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure vault is available
if ! command -v vault &> /dev/null; then
    echo -e "${RED}Error: vault command not found${NC}"
    exit 1
fi

# Ensure jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq command not found${NC}"
    exit 1
fi

# Function to read multi-line input
read_multiline() {
    local result=""
    local line=""
    echo -e "${YELLOW}Enter values (one per line, finish with two empty lines):${NC}"
    while true; do
        read -r line
        if [ -z "$line" ]; then
            if [ -z "$prev_line" ]; then
                break
            fi
        fi
        if [ -n "$line" ]; then
            if [ -n "$result" ]; then
                result="$result,$line"
            else
                result="$line"
            fi
        fi
        prev_line="$line"
    done
    echo "$result"
}

# Prompt for certificate details
echo -e "${YELLOW}Enter the common name (e.g., ns-elastic-01.local):${NC}"
read -r common_name

echo -e "${YELLOW}Enter a short name for the certificate type (e.g., http, transport):${NC}"
read -r short_name

echo -e "${YELLOW}Enter IP SANs:${NC}"
ip_sans=$(read_multiline)

echo -e "${YELLOW}Enter SANs:${NC}"
sans=$(read_multiline)

# Create output directories
cert_dir="$CERTS_BASE_DIR/$common_name"
mkdir -p "$cert_dir"

# Generate certificates using vault
echo -e "${GREEN}Generating certificates...${NC}"
cert_data=$(vault write -format=json "$PKI_ENGINE/issue/$ROLE_NAME" \
    common_name="$common_name" \
    alt_names="$sans" \
    ip_sans="$ip_sans" \
    ttl="$TTL")

# Extract and save certificates
echo "$cert_data" | jq -r '.data.private_key' > "$cert_dir/${short_name}.key"
echo "$cert_data" | jq -r '.data.certificate' > "$cert_dir/${short_name}.pem"
echo "$cert_data" | jq -r '.data.issuing_ca' > "$cert_dir/${short_name}-ca.pem"
echo "$cert_data" | jq -r '.data.ca_chain[]' > "$cert_dir/${short_name}-chain.pem"

# Set permissions
chmod 600 "$cert_dir"/*

echo -e "${GREEN}Certificates generated successfully in $cert_dir${NC}"
echo -e "${GREEN}Files generated:${NC}"
ls -l "$cert_dir"
