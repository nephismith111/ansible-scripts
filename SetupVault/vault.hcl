ui = true
#mlock = true
#disable_mlock = true
storage "raft" {
  path = "/opt/vault/data"

  node_id = "ns-hashi-01"
  retry_join {
    leader_api_addr = "https://192.168.86.21:8200"
  }
}

# HTTPS listener
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/etc/vault.d/certs/vault.crt"
  tls_key_file  = "/etc/vault.d/certs/vault.key"
}

cluster_addr = "https://192.168.86.21:8201"
api_addr = "https://192.168.86.21:8200"
