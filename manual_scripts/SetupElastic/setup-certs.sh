# part of a bash function that creates a certificate p12 that works for elasticsearch. Generated with the aid of several llms
function generate_certificate() {
    local node="$1"
    local cert_type="$2"
    local common_name="$3"
    local sans="$4"
    local ip_sans="$5"
    local password="$6"
    local output_dir="$7"

    echo -e "${yellow}Generating $cert_type certificate for $node...${reset}"

    cert_data=$(vault write -format=json "$intermediate_pki_engine/issue/$role" \
        common_name="$common_name" \
        alt_names="$sans" \
        ip_sans="$ip_sans" \
        ttl="$ttl")

    private_key=$(echo "${cert_data}" | jq -r '.data.private_key')
    certificate=$(echo "${cert_data}" | jq -r '.data.certificate')

    echo "${private_key}" > "$output_dir/${node}_${cert_type}_private_key.pem"
    echo "${certificate}" > "$output_dir/${node}_${cert_type}_cert.pem"

    openssl pkcs12 -export \
        -inkey "$output_dir/${node}_${cert_type}_private_key.pem" \
        -in "$output_dir/${node}_${cert_type}_cert.pem" \
        -out "$output_dir/${node}_${cert_type}_temp.p12" \
        -passout pass:"$password" \
        -name "${node}_${cert_type}"

    keytool -importkeystore \
        -srckeystore "$output_dir/${node}_${cert_type}_temp.p12" \
        -srcstoretype PKCS12 \
        -srcstorepass "$password" \
        -destkeystore "$output_dir/${node}_${cert_type}.p12" \
        -deststoretype PKCS12 \
        -deststorepass "$password" \
        -alias "${node}_${cert_type}"

    keytool -importcert \
        -noprompt \
        -keystore "$output_dir/${node}_${cert_type}.p12" \
        -storepass "$password" \
        -alias "ca_chain" \
        -file "elastic_kibana_fleet_certs/ca_chain/ca_chain.pem"

    rm "$output_dir/${node}_${cert_type}_temp.p12"

    echo -e "${green}Certificate $cert_type for $node generated successfully.${reset}"

    echo -e "${yellow}Verifying contents of ${node}_${cert_type}.p12:${reset}"
    keytool -list -keystore "$output_dir/${node}_${cert_type}.p12" -storepass "$password"
}