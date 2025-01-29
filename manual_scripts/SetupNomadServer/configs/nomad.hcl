data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0"
datacenter = "ns-dc-1"
name = "nomad-server-01"
log_level = "INFO"

server {
  enabled          = true
  bootstrap_expect = 1
  encrypt = "dXAtMIywG6vCtZoMqRmPprrDw1k32oG9GrPFHrNs6JU="
}

client {
  enabled = false
  servers = ["127.0.0.1"]
}

consul {
  address = "127.0.0.1:8500"
  server_service_name = "nomad"
  client_service_name = "nomad-client"
  auto_advertise = true
  server_auto_join = true
}

