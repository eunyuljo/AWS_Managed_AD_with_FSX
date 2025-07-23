# Data source for Windows Server AMI
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for EC2
resource "aws_security_group" "ec2" {
  name_prefix = "${var.environment}-ec2"
  vpc_id      = var.vpc_id

  # RDP access
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allow_rdp_from_internet ? ["0.0.0.0/0"] : [var.vpc_cidr]
  }

  # WinRM HTTP
  ingress {
    from_port   = 5985
    to_port     = 5985
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

  # SMB for FSx access
  ingress {
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
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
    Name = "${var.environment}-ec2-sg"
  })
}

# IAM Role for EC2 to join domain
resource "aws_iam_role" "ec2_domain_join" {
  name = "${var.environment}-ec2-domain-join-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for domain join
resource "aws_iam_role_policy" "ec2_domain_join" {
  name = "${var.environment}-ec2-domain-join-policy"
  role = aws_iam_role.ec2_domain_join.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ds:CreateComputer",
          "ds:DescribeDirectories"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach SSM managed policy
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.ec2_domain_join.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_domain_join" {
  name = "${var.environment}-ec2-domain-join-profile"
  role = aws_iam_role.ec2_domain_join.name

  tags = var.tags
}

# User Data script for domain join
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.ps1", {
    domain_name     = var.domain_name
    domain_dns_ips  = join(",", var.domain_dns_ips)
    admin_username  = var.domain_admin_username
    admin_password  = var.domain_admin_password
  }))
}

# EC2 Instance
resource "aws_instance" "domain_joined" {
  ami                    = data.aws_ami.windows.id
  instance_type         = var.instance_type
  key_name              = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id                   = var.subnet_id
  iam_instance_profile        = aws_iam_instance_profile.ec2_domain_join.name
  associate_public_ip_address = true

  user_data = local.user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-domain-joined-ec2"
  })
}