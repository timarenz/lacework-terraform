datacenter = "dc1"
data_dir = "/opt/consul"
bind_addr =  "{{GetInterfaceIP \"ens5\"}}"
retry_join = ["${retry_join}"]
addresses = {
    dns = "{{GetInterfaceIP \"ens5\"}}"
}
ports = {
    dns = 53
}
recursors = ["1.1.1.1","1.0.0.1"]
server = true
bootstrap_expect = ${server_count}
client_addr = "0.0.0.0"
ui = true
performance {
  raft_multiplier = 1
}