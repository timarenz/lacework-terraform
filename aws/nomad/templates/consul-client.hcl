datacenter = "dc1"
data_dir = "/opt/consul"
bind_addr =  "{{GetInterfaceIP \"ens5\"}}"
retry_join = ["${retry_join}"]
