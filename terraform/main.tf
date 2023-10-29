terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_vpc" "mediawiki" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "mediawiki"
  }
}

resource "aws_subnet" "mediawiki" {
  vpc_id     = aws_vpc.mediawiki.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "mediawiki"
  }
}

resource "aws_key_pair" "mediawiki" {
  key_name   = "mediawiki"
  public_key = file("~/.ssh/mediawiki.pub")
}

resource "aws_security_group" "mediawiki" {
  name        = "mediawiki"
  description = "All necessary inbound and outbound traffic"
  vpc_id      = aws_vpc.mediawiki.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "mediawiki" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.mediawiki.id
  key_name      = aws_key_pair.mediawiki.key_name
  vpc_security_group_ids = [aws_security_group.mediawiki.id]
  tags = {
    Name = "mediawiki"
  }
}

resource "aws_ebs_volume" "mediawiki" {
  availability_zone = aws_instance.mediawiki.availability_zone
  size              = 50
  tags = {
    Name = "mediawiki"
  }
}

resource "aws_volume_attachment" "mediawiki" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.mediawiki.id
  instance_id = aws_instance.mediawiki.id
}

resource "aws_internet_gateway" "mediawiki" {
  vpc_id = aws_vpc.mediawiki.id
}

resource "aws_route_table" "mediawiki" {
  vpc_id = aws_vpc.mediawiki.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mediawiki.id
  }
}

resource "aws_route_table_association" "mediawiki" {
  subnet_id      = aws_subnet.mediawiki.id
  route_table_id = aws_route_table.mediawiki.id
}

resource "aws_eip" "mediawiki" {
  instance = aws_instance.mediawiki.id
}
