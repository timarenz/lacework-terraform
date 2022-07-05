output "registry_url" {
  value = aws_ecr_repository.main.repository_url
}

output "proxy_scanner_public_ip" {
  value = aws_instance.proxy_scanner.public_ip
}

output "proxy_scanner_role_arn" {
  value = aws_iam_role.proxy_scanner.arn
}
