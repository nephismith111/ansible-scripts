tls {
  http = true
  rpc = true
  verify_server_hostname = true
  ca_file = "/etc/nomad.d/certs/root-ca.crt"
  cert_file = "/etc/nomad.d/certs/nomad.crt"
  key_file = "/etc/nomad.d/certs/nomad.key"

}
