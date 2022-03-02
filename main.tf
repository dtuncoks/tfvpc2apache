provider "aws" {
  region = "us-east-2"

}

# Create a VPV
resource "aws_vpc" "apache_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    name = var.tag
  }
}

# Create Internet Gateway

resource "aws_internet_gateway" "apache_igw" {
  vpc_id = aws_vpc.apache_vpc.id

  tags = {
    name = var.tag
  }
}

# create custom route table
resource "aws_route_table" "apache_rt" {
  vpc_id = aws_vpc.apache_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.apache_igw.id
  }

  ##route {
#    ipv6_cidr_block        = "::/0"
 #   egress_only_gateway_id = aws_internet_gateway.apache_igw.id
  #}

#    tags = {
#    name = var.tag
#   }

}

# Create a subnet
resource "aws_subnet" "apache_sub" {
  vpc_id               = aws_vpc.apache_vpc.id
  cidr_block           = "10.0.1.0/24"
  availability_zone = "us-east-2b"

  tags = {
    name = var.tag
  }
}

# Associate Subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.apache_sub.id
  route_table_id = aws_route_table.apache_rt.id

}

# Create security Group to allow port 22, 80. 443
resource "aws_security_group" "apache_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.apache_vpc.id

  ingress {
    description = "https from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = var.tag
  }
}

# Create a network interface with an IP in the subnet
resource "aws_network_interface" "apache_nic" {
  subnet_id       = aws_subnet.apache_sub.id
  private_ips     = ["10.0.1.40"]
  security_groups = [aws_security_group.apache_sg.id]
}

# Assign a Elastic IP
resource "aws_eip" "apache_eip" {
  vpc                       = true
  network_interface         = aws_network_interface.apache_nic.id
  associate_with_private_ip = "10.0.1.40"
  depends_on                = [aws_internet_gateway.apache_igw]
  tags = {
    Name = var.tag
  }
}

#create an Instance and Install/enable Apache
resource "aws_instance" "apache" {
  ami               = "ami-0fb653ca2d3203ac1"
  instance_type     = "t2.micro"
  availability_zone = "us-east-2b"
  key_name = "apache_key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.apache_nic.id
  }

  user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install apache2 -y
            sudo systemctl start apache2
            sudo bash -c 'echo This is a project using Terraform and a keypair from AWS console to deploy an Apache Web server. I also used Outputs to see info on the server. > /var/www/html/index.html'
            EOF

  tags = {
    Name = var.tag
  }
}

output "server_private_ip" {

    value = aws_instance.apache.private_ip
}
output "server_public_ip" {

    value = aws_eip.apache_eip.public_ip
}