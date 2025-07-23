variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where AD will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for AD deployment"
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name for Managed Microsoft AD"
  type        = string
}

variable "admin_password" {
  description = "Password for the directory administrator"
  type        = string
  sensitive   = true
}

variable "edition" {
  description = "Edition of the Managed Microsoft AD"
  type        = string
  default     = "Standard"
}

variable "dns_forwarders" {
  description = "List of DNS forwarders for external domains"
  type = list(object({
    domain_name = string
    dns_ips     = list(string)
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}