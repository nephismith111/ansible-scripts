datacenter = "ns-dc-1"
data_dir = "/opt/consul"
# client_addr
# The address to which Consul will bind client interfaces, including the HTTP and DNS
# servers. By default, this is "127.0.0.1", allowing only loopback connections. In
# Consul 1.0 and later this can be set to a space-separated list of addresses to bind
# to, or a go-sockaddr template that can potentially resolve to multiple addresses.
client_addr = "0.0.0.0"
ui_config{
  enabled = true
}
server = true

# Bind addr
# You may use IPv4 or IPv6 but if you have multiple interfaces you must be explicit.
#bind_addr = "[::]" # Listen on all IPv6
bind_addr = "0.0.0.0" # Listen on all IPv4
# Advertise addr - if you want to point clients to a different address than bind or LB.
advertise_addr = "192.168.86.21"
bootstrap_expect=1
encrypt = "PiGq3RVVWNbXTle7DH8L5iZel2SHMkbswyTd08dqALs="
#retry_join = ["consul.domain.internal"]
retry_join = ["192.168.86.21"]
#retry_join = ["[::1]:8301"]
#retry_join = ["consul.domain.internal", "10.0.4.67"]
