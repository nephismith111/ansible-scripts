# From https://developer.hashicorp.com/vault/install

# Initial installation of Vault
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vault



# This part requires manual operation
# Wake up in https dev mode to get the first real certificate:
vault server -dev -dev-root-token-id=root -dev-tls -dev-listen-address="0.0.0.0:8200" -dev-tls-san="0.0.0.0"


## Create the certificates and put them in /etc/vault.d/certs/
# ca.crt, vault.key, vault.cert

# Then copy the ca.crt file over to this directory
cp ca.crt /usr/local/share/ca-certificates/
# Load the certificates into the system
update-ca-certificates


# Setup keepalived for HA for a consistant crl url for the certificates
sudo apt install keepalived -y
# Copy the keepalived.conf to remote: /etc/keepalived/keepalived.conf
# Enable and start keepalived:
sudo systemctl enable keepalived
sudo systemctl start keepalived


# how to start vault manually form root:
vault server -config=/etc/vault.d/vault.hcl

#Set up permissions
sudo chown -R vault:vault /opt/vault/
sudo chown -R vault:vault /etc/vault.d/

# To test permissions:
sudo -u vault -s

# To Install service, copy vault.service to /etc/systemd/system/vault.service
sudo systemctl enable vault.service
sudo systemctl start vault.service


