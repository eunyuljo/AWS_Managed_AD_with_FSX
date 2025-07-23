output "instance_id" {
  description = "ID of the DNS server instance"
  value       = aws_instance.dns_server.id
}

output "private_ip" {
  description = "Private IP address of the DNS server"
  value       = aws_instance.dns_server.private_ip
}

output "public_ip" {
  description = "Public IP address of the DNS server"
  value       = aws_instance.dns_server.public_ip
}

output "security_group_id" {
  description = "Security group ID for the DNS server"
  value       = aws_security_group.dns_server.id
}

output "dns_zone_name" {
  description = "DNS zone name served by this server"
  value       = var.dns_zone_name
}

output "instance_state" {
  description = "State of the DNS server instance"
  value       = aws_instance.dns_server.instance_state
}