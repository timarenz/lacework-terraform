datacenter = "dc1"
data_dir = "/opt/nomad"
server {
  enabled = true
  bootstrap_expect = ${server_count}
  server_join {
    retry_join = [ "${retry_join}" ]
  }
}
