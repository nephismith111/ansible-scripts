# Setup tls
verify_incoming = false
verify_outgoing = true
verify_server_hostname = true

ca_file = "/etc/consul.d/certs/consul-ca.pem"
cert_file = "/etc/consul.d/certs/consul-cert.pem"
key_file = "/etc/consul.d/certs/consul-key.pem"

ports {
  https = 8500
  http = -1
}

