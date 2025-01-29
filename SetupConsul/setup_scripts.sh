# Install consul
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install consul
# verify
consul -v

# Create an encrypt key
consul keygen


# Setup acl
consul acl bootstrap
# Remember to save the bootstrap token

# Create policies
# It's hard to do this initial setup in https, so I suggest finishing the initial policy and token registration before switching to https, then move the default port to https - there was a bug in consul that prevented https then acl when I tried to do https first)
sudo mkdir -p /etc/consul.d/policies
cd /etc/consul.d/policies
# Copy over the policies

# Load the token
export CONSUL_HTTP_TOKEN=<management token>

############ Create consul server
consul acl policy create \
  -name "server-policy" \
  -description "Policy for primary Consul Servers" \
  -rules @server.policy.hcl

# Create the token (remember to save it - probably in vault)
consul acl token create -description "Token for Consul Server 1" -policy-name "server-policy"

############ Create admin policy
consul acl policy create \
  -name "admin-policy" \
  -description "Policy for Consul Admins" \
  -rules @admin.policy.hcl

consul acl token create -description "Token for Nephi (Admin)" -policy-name "admin-policy"

############ Create nomad server policy
consul acl policy create \
  -name "nomad-server-policy" \
  -description "Policy for Nomad Servers" \
  -rules @nomad-server.policy.hcl

consul acl token create -description "Token for Nomad Server 01" -policy-name "nomad-server-policy"
consul acl token create -description "Token for Nomad Server 02" -policy-name "nomad-server-policy"
consul acl token create -description "Token for Nomad Server 03" -policy-name "nomad-server-policy"



# Create certs directory
sudo mkdir -p /etc/consul.d/certs
# Copy over the certs - server cert must include SANS `server.<consul datactr>.consul` in addition to the rest of the SANS and IP SANS
# I used vault to manually provision the cert. I plan to script it out later, but this is fast and easy for limited certificates during initial build out phase.

# Set permissions
chown -R consul:consul /etc/consul.d/
chown -R consul:consul /opt/consul

# Copy over the consul.service to /etc/systemd/system/consul.service
sudo systemctl enable consul.service
sudo systemctl start consul.service