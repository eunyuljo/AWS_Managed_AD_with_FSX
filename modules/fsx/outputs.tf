output "fsx_id" {
  description = "ID of the FSx Windows File System"
  value       = aws_fsx_windows_file_system.main.id
}

output "dns_name" {
  description = "DNS name of the FSx Windows File System"
  value       = aws_fsx_windows_file_system.main.dns_name
}

output "network_interface_ids" {
  description = "Network Interface IDs of the FSx Windows File System"
  value       = aws_fsx_windows_file_system.main.network_interface_ids
}

output "preferred_subnet_id" {
  description = "Preferred subnet ID of the FSx Windows File System"
  value       = aws_fsx_windows_file_system.main.preferred_subnet_id
}

output "vpc_id" {
  description = "VPC ID of the FSx Windows File System"
  value       = aws_fsx_windows_file_system.main.vpc_id
}

output "security_group_id" {
  description = "Security group ID for FSx"
  value       = aws_security_group.fsx.id
}