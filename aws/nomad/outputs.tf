output "nomad_server_public_ips" {
  value = module.nomad_server[*].public_ip
}

output "nomad_client_public_ips" {
  value = module.nomad_client[*].public_ip
}
