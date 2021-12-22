output "nexus_public_ip" {
  value = module.nexus.public_ip
}

output "proxy_scanner_public_ip" {
  value = module.proxy_scanner.public_ip
}

output "nexus_admin_portal" {
  value = "http://${module.nexus.public_ip}:8081"
}

output "nexus_registry" {
  value = "https://${aws_route53_record.nexus.name}"
}
