variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EC2 will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for EC2 deployment"
  type        = string
}

variable "domain_name" {
  description = "Domain name to join"
  type        = string
}

variable "domain_dns_ips" {
  description = "List of domain DNS IP addresses"
  type        = list(string)
}

variable "domain_admin_username" {
  description = "Domain administrator username"
  type        = string
  default     = "Admin"
}

variable "domain_admin_password" {
  description = "Domain administrator password"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_pair_name" {
  description = "Name of the EC2 Key Pair for SSH access"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 50
}

variable "allow_rdp_from_internet" {
  description = "Allow RDP access from internet (0.0.0.0/0)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}