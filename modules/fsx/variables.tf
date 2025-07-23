variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where FSx will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for FSx deployment"
  type        = string
}

variable "active_directory_id" {
  description = "Active Directory ID for domain join"
  type        = string
}

variable "storage_capacity" {
  description = "Storage capacity for FSx in GB"
  type        = number
  default     = 300
}

variable "throughput_capacity" {
  description = "Throughput capacity for FSx in MB/s"
  type        = number
  default     = 32
}

variable "backup_retention_days" {
  description = "Number of days to retain automatic backups"
  type        = number
  default     = 7
}

variable "backup_start_time" {
  description = "Daily automatic backup start time"
  type        = string
  default     = "03:00"
}

variable "maintenance_start_time" {
  description = "Weekly maintenance start time"
  type        = string
  default     = "1:05:00"
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}