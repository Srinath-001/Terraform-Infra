module "vpc" {
  source   = "./modules/vpc"
  name     = "srinath-vpc"
  vpc_cidr = var.vpc_cidr
}

module "subnets" {
  source              = "./modules/subnets"
  vpc_id              = module.vpc.vpc_id
  public_subnet_cidrs = var.public_subnet_cidrs
  azs                 = var.azs
}

resource "aws_internet_gateway" "igw" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "srinath-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = module.vpc.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "srinath-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(module.subnets.public_subnet_ids)
  subnet_id      = module.subnets.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2_sg" {
  name        = "srinath-ec2-sg"
  description = "Allow SSH"
  vpc_id      = module.vpc.vpc_id

  ingress {
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
    Name = "srinath-ec2-sg"
  }
}

resource "tls_private_key" "srinath" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "srinath_key" {
  key_name   = "srinath_key"
  public_key = tls_private_key.srinath.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.srinath.private_key_pem
  filename        = "${path.module}/srinath_key.pem"
  file_permission = "0400"
}

resource "aws_instance" "python_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = module.subnets.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.srinath_key.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y python3
              EOF

  tags = {
    Name = "srinath-python-ec2"
  }
}