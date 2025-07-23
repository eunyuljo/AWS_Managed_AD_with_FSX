terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  common_tags = {
    Terraform   = "true"
    Environment = var.environment
    Project     = "AWS-Managed-AD-FSx"
  }
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  vpc_name              = var.vpc_name
  vpc_cidr              = var.vpc_cidr
  availability_zones    = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnet_cidrs  = var.private_subnet_cidrs
  public_subnet_cidrs   = var.public_subnet_cidrs
  tags                  = local.common_tags
}

# Active Directory Module
module "active_directory" {
  source = "./modules/active-directory"

  environment      = var.environment
  vpc_id          = module.networking.vpc_id
  vpc_cidr        = module.networking.vpc_cidr_block
  subnet_ids      = module.networking.private_subnets
  domain_name     = var.ad_domain_name
  admin_password  = var.ad_admin_password
  edition         = var.ad_edition
  tags            = local.common_tags
}

# FSx Module
module "fsx" {
  source = "./modules/fsx"

  environment          = var.environment
  vpc_id              = module.networking.vpc_id
  vpc_cidr            = module.networking.vpc_cidr_block
  subnet_id           = module.networking.private_subnets[0]
  active_directory_id = module.active_directory.directory_id
  storage_capacity    = var.fsx_storage_capacity
  throughput_capacity = var.fsx_throughput_capacity
  tags                = local.common_tags

  depends_on = [module.active_directory]
}

# EC2 Module
module "ec2" {
  source = "./modules/ec2"

  environment            = var.environment
  vpc_id                = module.networking.vpc_id
  vpc_cidr              = module.networking.vpc_cidr_block
  subnet_id             = module.networking.public_subnets[0]
  domain_name           = var.ad_domain_name
  domain_dns_ips        = module.active_directory.dns_ip_addresses
  domain_admin_username   = var.ec2_domain_admin_username
  domain_admin_password   = var.ad_admin_password
  instance_type           = var.ec2_instance_type
  key_pair_name           = var.ec2_key_pair_name
  root_volume_size        = var.ec2_root_volume_size
  #allow_rdp_from_internet = var.ec2_allow_rdp_from_internet
  tags                    = local.common_tags

  depends_on = [module.active_directory]
}