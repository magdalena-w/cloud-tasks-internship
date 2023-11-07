resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-terraform-internship"
    Owner = "mwalesa"
    Project = "2023_internship_wro"
  }
}

resource "aws_subnet" "subnet_a" {
  count = 3
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.${count.index}.0/24"
  availability_zone = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-${count.index}"
    Owner = "mwalesa"
    Project = "2023_internship_wro"
  }
}

resource "aws_security_group" "sg_tg" {
  name = "sg_tg"
  description = "SG for Target Group"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.sg_lb.id]

  }
}

resource "aws_security_group" "sg_lb" {
  name        = "sg_lb"
  description = "SG for loadbalancer"
  vpc_id      = aws_vpc.my_vpc.id

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

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "internet_gateway_terraform_internship"
    Owner = "mwalesa"
    Project = "2023_internship_wro"
  }
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.my_igw.id}"
  }
  tags = {
    Name = "Route to internet"
    Owner = "mwalesa"
    Project = "2023_internship_wro"
  }
}

resource "aws_route_table_association" "subnet_association" {
  count = 3
  subnet_id = element(aws_subnet.subnet_a[*].id, count.index)
  route_table_id = aws_route_table.my_route_table.id
}

output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.subnet_a[*].id
}

output "lb_sg_id" {
  value = aws_security_group.sg_lb.id
}

output "tg_sg_id" {
  value = aws_security_group.sg_tg.id
}