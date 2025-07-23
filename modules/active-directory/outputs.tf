output "directory_id" {
  description = "ID of the Managed Microsoft AD"
  value       = aws_directory_service_directory.managed_ad.id
}

output "dns_ip_addresses" {
  description = "DNS IP addresses of the Managed Microsoft AD"
  value       = aws_directory_service_directory.managed_ad.dns_ip_addresses
}

output "access_url" {
  description = "Access URL for the directory"
  value       = aws_directory_service_directory.managed_ad.access_url
}

output "security_group_id" {
  description = "Security group ID for Managed AD"
  value       = aws_security_group.managed_ad.id
}