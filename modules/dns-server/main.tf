# Data source for Amazon Linux AMI (more reliable)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Security Group for DNS Server
resource "aws_security_group" "dns_server" {
  name_prefix = "${var.environment}-dns-server"
  vpc_id      = var.vpc_id

  # DNS UDP
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # DNS TCP
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allow_ssh_from_internet ? ["0.0.0.0/0"] : [var.vpc_cidr]
  }

  # ICMP for ping
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-dns-server-sg"
  })
}

# User Data script for DNS server setup
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    dns_zone_name    = var.dns_zone_name
    dns_records      = var.dns_records
    forwarder_dns    = var.forwarder_dns
  }))
}

# DNS Server EC2 Instance
resource "aws_instance" "dns_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type         = var.instance_type
  key_name              = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.dns_server.id]
  subnet_id             = var.subnet_id
  associate_public_ip_address = var.assign_public_ip

  user_data = local.user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-dns-server"
    Role = "DNS-Server"
  })
}