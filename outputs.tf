# Networking Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnets
}

# Active Directory Outputs
output "managed_ad_id" {
  description = "ID of the Managed Microsoft AD"
  value       = module.active_directory.directory_id
}

output "managed_ad_dns_ip_addresses" {
  description = "DNS IP addresses of the Managed Microsoft AD"
  value       = module.active_directory.dns_ip_addresses
}

output "managed_ad_access_url" {
  description = "Access URL for the directory"
  value       = module.active_directory.access_url
}

# # FSx Outputs
# output "fsx_id" {
#   description = "ID of the FSx Windows File System"
#   value       = module.fsx.fsx_id
# }

# output "fsx_dns_name" {
#   description = "DNS name of the FSx Windows File System"
#   value       = module.fsx.dns_name
# }

# output "fsx_network_interface_ids" {
#   description = "Network Interface IDs of the FSx Windows File System"
#   value       = module.fsx.network_interface_ids
# }

# output "fsx_preferred_subnet_id" {
#   description = "Preferred subnet ID of the FSx Windows File System"
#   value       = module.fsx.preferred_subnet_id
# }

# EC2 Outputs
output "domain-joined_ec2_instance_id" {
  description = "ID of the domain-joined EC2 instance"
  value       = module.ec2.instance_id
}

output "domain-joined_ec2_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = module.ec2.private_ip
}

output "domain-joined_ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2.public_ip
}

output "domain-joined_ec2_instance_state" {
  description = "State of the EC2 instance"
  value       = module.ec2.instance_state
}

# DNS Server Outputs
output "dns_server_instance_id" {
  description = "ID of the DNS server instance"
  value       = module.dns_server.instance_id
}

output "dns_server_private_ip" {
  description = "Private IP address of the DNS server"
  value       = module.dns_server.private_ip
}

output "dns_server_public_ip" {
  description = "Public IP address of the DNS server"
  value       = module.dns_server.public_ip
}

output "dns_server_zone_name" {
  description = "DNS zone name served by the DNS server"
  value       = module.dns_server.dns_zone_name
}