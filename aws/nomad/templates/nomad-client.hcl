datacenter = "dc1"
data_dir = "/opt/nomad"
client {
  enabled = true
  server_join {
    retry_join = [ "${retry_join}" ]
  }
  meta {
    app = "${app_type}"
  }
}

plugin "docker" {
  config {
    allow_privileged = true
  }
}