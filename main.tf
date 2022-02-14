provider "aws" {
    region = "eu-central-1"
}

variable vpc_cidr_blocks {}
variable env_prefix {}
variable subnet_cidr_blocks {}

variable avail_zone {}
variable my_ip {}
variable instance_type {}
variable public_key_location {}
resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_blocks
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_blocks
    availability_zone = var.avail_zone
    tags = {
         Name: "${var.env_prefix}-subnet-1"
    }
}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id 

  tags = {
    Name =  "${var.env_prefix}-igw"
  }
}
resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
    tags = {
    Name =  "${var.env_prefix}-rtb"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.myapp-subnet-1.id 
  route_table_id = aws_route_table.myapp-route-table.id
}


resource "aws_security_group" "myapp-sg" {
  name        = "myapp-sg"
  vpc_id      = aws_vpc.myapp-vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip]

  }

    ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name =  "${var.env_prefix}-sg"
  }
}

data "aws_ami" "amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "ami_id" {
  value = data.aws_ami.amazon-linux-image
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.public_key_location)
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon-linux-image.id 
  instance_type = var.instance_type
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  associate_public_ip_address = true 
  key_name = aws_key_pair.ssh-key.key_name
  tags = {
    Name = "${var.env_prefix}-server"
  }
    user_data = file("script.sh")

}


