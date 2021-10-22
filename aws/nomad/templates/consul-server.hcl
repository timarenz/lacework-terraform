datacenter = "dc1"
data_dir = "/opt/consul"
bind_addr =  "{{GetInterfaceIP \"ens5\"}}"
retry_join = ["${retry_join}"]

server = true
bootstrap_expect = ${server_count}
client_addr = "0.0.0.0"
ui = true

performance {
  raft_multiplier = 1
}