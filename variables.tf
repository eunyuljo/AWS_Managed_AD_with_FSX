variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-northeast-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "fsx-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "ad_domain_name" {
  description = "Domain name for Managed Microsoft AD"
  type        = string
  default     = "corp.example.com"
}

variable "ad_admin_password" {
  description = "Password for the directory administrator"
  type        = string
  sensitive   = true
  validation {
    condition = length(var.ad_admin_password) >= 8 && length(var.ad_admin_password) <= 64
    error_message = "Password must be between 8 and 64 characters long."
  }
}

variable "ad_edition" {
  description = "Edition of the Managed Microsoft AD"
  type        = string
  default     = "Standard"
  validation {
    condition = contains(["Standard", "Enterprise"], var.ad_edition)
    error_message = "AD Edition must be either 'Standard' or 'Enterprise'."
  }
}

variable "fsx_storage_capacity" {
  description = "Storage capacity for FSx in GB"
  type        = number
  default     = 300
  validation {
    condition = var.fsx_storage_capacity >= 32 && var.fsx_storage_capacity <= 65536
    error_message = "FSx storage capacity must be between 32 and 65536 GB."
  }
}

variable "fsx_throughput_capacity" {
  description = "Throughput capacity for FSx in MB/s"
  type        = number
  default     = 32
  validation {
    condition = contains([8, 16, 32, 64, 128, 256, 512, 1024, 2048], var.fsx_throughput_capacity)
    error_message = "FSx throughput capacity must be one of: 8, 16, 32, 64, 128, 256, 512, 1024, 2048."
  }
}

# EC2 Variables
variable "ec2_instance_type" {
  description = "EC2 instance type for domain-joined instance"
  type        = string
  default     = "t3.medium"
}

variable "ec2_key_pair_name" {
  description = "Name of the EC2 Key Pair for RDP access"
  type        = string
  default     = null
}

variable "ec2_root_volume_size" {
  description = "Size of the EC2 root volume in GB"
  type        = number
  default     = 50
  validation {
    condition = var.ec2_root_volume_size >= 30 && var.ec2_root_volume_size <= 1000
    error_message = "EC2 root volume size must be between 30 and 1000 GB."
  }
}

variable "ec2_domain_admin_username" {
  description = "Domain administrator username for EC2 domain join"
  type        = string
  default     = "Admin"
}

variable "ec2_allow_rdp_from_internet" {
  description = "Allow RDP access from internet (0.0.0.0/0)"
  type        = bool
  default     = true
}

# DNS Forwarder Variables
variable "ad_dns_forwarders" {
  description = "List of DNS forwarders for external domains"
  type = list(object({
    domain_name = string
    dns_ips     = list(string)
  }))
  default = []
  
  validation {
    condition = alltrue([
      for forwarder in var.ad_dns_forwarders : 
      length(forwarder.dns_ips) > 0 && length(forwarder.dns_ips) <= 4
    ])
    error_message = "Each DNS forwarder must have between 1 and 4 DNS IP addresses."
  }
}

# DNS Server Variables
variable "dns_server_instance_type" {
  description = "EC2 instance type for DNS server"
  type        = string
  default     = "t3.micro"
}

variable "dns_server_key_pair_name" {
  description = "Name of the EC2 Key Pair for DNS server SSH access"
  type        = string
  default     = null
}

variable "dns_server_root_volume_size" {
  description = "Size of the DNS server root volume in GB"
  type        = number
  default     = 20
  validation {
    condition = var.dns_server_root_volume_size >= 8 && var.dns_server_root_volume_size <= 100
    error_message = "DNS server root volume size must be between 8 and 100 GB."
  }
}

variable "dns_server_assign_public_ip" {
  description = "Assign public IP to DNS server"
  type        = bool
  default     = true
}

variable "dns_server_allow_ssh_from_internet" {
  description = "Allow SSH access to DNS server from internet"
  type        = bool
  default     = true
}

variable "dns_server_zone_name" {
  description = "DNS zone name to serve"
  type        = string
  default     = "example.local"
}

variable "dns_server_records" {
  description = "List of DNS records to create"
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default = [
    {
      name  = "test"
      type  = "A"
      value = "10.0.1.100"
    },
    {
      name  = "web"
      type  = "A" 
      value = "10.0.1.200"
    }
  ]
}

variable "dns_server_forwarder_dns" {
  description = "Upstream DNS servers for forwarding"
  type        = string
  default     = "8.8.8.8; 8.8.4.4"
}