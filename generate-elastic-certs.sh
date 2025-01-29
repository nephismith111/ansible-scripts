#!/bin/bash

# Default configuration
VAULT_ADDR=${VAULT_ADDR:-"https://192.168.86.21:8200"}
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

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        for i in {1..4}; do
            if [ $(echo "$ip" | cut -d. -f$i) -gt 255 ]; then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Function to read multi-line input
read_multiline() {
    local input_type=$1
    local result=""
    local line=""
    local empty_lines=0
    
    echo -e "${YELLOW}Enter values (one per line, finish with an empty line):${NC}"
    while [ $empty_lines -lt 1 ]; do
        read -r line
        
        if [ -z "$line" ]; then
            ((empty_lines++))
        else
            if [ "$input_type" = "ip" ]; then
                if ! validate_ip "$line"; then
                    echo -e "${RED}Invalid IP address: $line${NC}"
                    continue
                fi
            fi
            
            if [ -n "$result" ]; then
                result="$result,$line"
            else
                result="$line"
            fi
            empty_lines=0
        fi
    done
    echo "$result"
}

# Prompt for certificate details
while true; do
    echo -e "${YELLOW}Enter the common name (e.g., ns-elastic-01.local):${NC}"
    read -r common_name
    if [ -n "$common_name" ]; then
        break
    fi
    echo -e "${RED}Common name cannot be empty${NC}"
done

while true; do
    echo -e "${YELLOW}Enter a short name for the certificate type (e.g., http, transport):${NC}"
    read -r short_name
    if [[ "$short_name" =~ ^(http|transport)$ ]]; then
        break
    fi
    echo -e "${RED}Short name must be either 'http' or 'transport'${NC}"
done

echo -e "${YELLOW}Enter IP SANs:${NC}"
ip_sans=$(read_multiline "ip")

echo -e "${YELLOW}Enter SANs:${NC}"
sans=$(read_multiline "dns")

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



#nsmith@ajftracerv:~/Nephi/repos/ansible-scripts$ ./generate-elastic-certs.sh
#Enter the common name (e.g., ns-elastic-01.local):
#ns-elastic-01
#Enter a short name for the certificate type (e.g., http, transport):
#http
#Enter IP SANs:
#192.18.86.30
#192.168.86.31
#127.0.0.1
#
#
#Enter SANs:
#localhost
#
#
#Generating certificates...
#Error writing data to pki-root-ca/issue/generic: Error making API request.
#
#URL: PUT https://192.168.86.21:8200/v1/pki-root-ca/issue/generic
#Code: 400. Errors:
#
#* the value "\x1b[1;33mEnter values (one per line" is not a valid IP address
#Certificates generated successfully in ./elastic-certs/ns-elastic-01
#Files generated:
#total 0
#-rw------- 1 nsmith nsmith 0 Jan 29 07:31 http-ca.pem
#-rw------- 1 nsmith nsmith 0 Jan 29 07:31 http-chain.pem
#-rw------- 1 nsmith nsmith 0 Jan 29 07:31 http.key
#-rw------- 1 nsmith nsmith 0 Jan 29 07:31 http.pem
#nsmith@ajftracerv:~/Nephi/repos/ansible-scripts$
