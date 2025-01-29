sudo apt-get update && \
  sudo apt-get install wget gpg coreutils
wget -O- https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
| sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update && sudo apt-get install nomad

# how to start and test nomad:      nomad agent -config=/etc/nomad.d
export NOMAD_TOKEN=<token>
export NOMAD_ADDR=https://<ip>:4646
# Create policies
nomad acl policy apply -description "Server Policy" server-policy server.policy.hcl
nomad acl token create -name="ns-nomad-server-01" -policy=server-policy -type=client
nomad acl token create -name="ns-nomad-server-02" -policy=server-policy -type=client
nomad acl token create -name="ns-nomad-server-03" -policy=server-policy -type=client

nomad acl policy apply -description "Admin Policy" admin-policy admin.policy.hcl

sudo chown -R nomad:nomad /etc/nomad.d
sudo chown -R nomad:nomad /opt/nomad

# Copy over the nomad.service to /etc/systemd/system/nomad.service
sudo systemctl enable nomad.service
sudo systemctl start nomad.service

# Setup certificates for nomad
CN = server.global.nomad, inculde the appropriate ip addresses and IP SANS
# Copy certs to /etc/nomad.d/certs


# Setup the certificate authority
# Copy root ca to /usr/local/share/ca-certificates

# Install consul
sudo apt-get install consul

# Copy all of the consul configs to /etc/consul.d
# Set ownership
sudo chown consul:consul /etc/consul.d
sudo chown -R consul:consul /opt/consul

# Copy over the service config for consul /etc/systemd/system/consul.service

# Enable and start consul
sudo systemctl enable consul
sudo systemctl start consul



