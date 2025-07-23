# Security Group for FSx
resource "aws_security_group" "fsx" {
  name_prefix = "${var.environment}-fsx"
  vpc_id      = var.vpc_id

  # SMB traffic
  ingress {
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # WinRM HTTPS
  ingress {
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-fsx-sg"
  })
}

# FSx for Windows File Server
resource "aws_fsx_windows_file_system" "main" {
  active_directory_id             = var.active_directory_id
  storage_capacity                = var.storage_capacity
  throughput_capacity            = var.throughput_capacity
  subnet_ids                     = [var.subnet_id]
  security_group_ids             = [aws_security_group.fsx.id]
  
  automatic_backup_retention_days = var.backup_retention_days
  daily_automatic_backup_start_time = var.backup_start_time
  weekly_maintenance_start_time   = var.maintenance_start_time

  tags = merge(var.tags, {
    Name = "${var.environment}-fsx-windows"
  })
}