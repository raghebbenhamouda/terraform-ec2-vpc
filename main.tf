provider "aws" {
    region = "eu-central-1"
}

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_blocks
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

module "myapp-subnet" {
  source = "./modules/subnet"
  subnet_cidr_blocks = var.subnet_cidr_blocks
  avail_zone = var.avail_zone
  env_prefix = var.env_prefix
  vpc_id = aws_vpc.myapp-vpc.id
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

}

module "myapp-server" {
  source = "./modules/webserver"
 vpc_id = aws_vpc.myapp-vpc.id
 env_prefix = var.env_prefix
 avail_zone = var.avail_zone
 image_name = var.image_name
 public_key_location = var.public_key_location
 instance_type = var.instance_type
 my_ip = var.my_ip
 subnet_id = module.myapp-subnet.subnet.id
}



