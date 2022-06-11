provider "aws" {
  region = "eu-west-2"
}

variable private_subnets_cidr_blocks {}
variable public_subnets_cidr_blocks {}
variable vpc_cidr_block {}

data "aws_availability_zones" "azs" {}

module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"
  name = "myapp-vpc"
  cidr = var.vpc_cidr_block
  private_subnets = var.private_subnets_cidr_blocks
  public_subnets = var.public_subnets_cidr_blocks
  azs = data.aws_availability_zones.azs.names
  enable_nat_gateway = true
  single_nat_gateway = true # all private subnets will route their internet traffic through this single NAT gateway
  enable_dns_hostnames = true # exp: when ec2 instance created it will also be assigned a public and private dns name
  tags={
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared" # eks controlor manager will use this tags to identify wich resources belong to the cluster 
  }  

  public_subnet_tags = { #required
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared" # myapp-eks-cluster is the name of the our cluster
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = { #required
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb" = 1

  }
}