datacenter = "ns-dc-1"
data_dir = "/opt/consul"

client_addr = "127.0.0.1"
ui_config{
  enabled = false
}

bind_addr = "0.0.0.0" # Listen on all IPv4

# Advertise addr - if you want to point clients to a different address than bind or LB.
advertise_addr = "192.168.86.26"
encrypt = "PiGq3RVVWNbXTle7DH8L5iZel2SHMkbswyTd08dqALs="

retry_join = ["192.168.86.21"]

