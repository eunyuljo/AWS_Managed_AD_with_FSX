variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where DNS server will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for DNS server deployment"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for DNS server"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of the EC2 Key Pair for SSH access"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "assign_public_ip" {
  description = "Assign public IP to DNS server"
  type        = bool
  default     = true
}

variable "allow_ssh_from_internet" {
  description = "Allow SSH access from internet (0.0.0.0/0)"
  type        = bool
  default     = true
}

variable "dns_zone_name" {
  description = "DNS zone name to serve"
  type        = string
  default     = "example.local"
}

variable "dns_records" {
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

variable "forwarder_dns" {
  description = "Upstream DNS servers for forwarding"
  type        = string
  default     = "8.8.8.8; 8.8.4.4"
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}