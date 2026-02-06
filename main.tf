variable "vpc_name" {
  type = string
  default="vpc-terraform-v2"
}

resource "aws_vpc" "minha_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = var.vpc_name
  }
}

# Correcao primeira issue
resource "aws_flow_log" "example" {
  log_destination      = "arn:aws:s3:::tiago-terraform-automation"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.minha_vpc.id
}

# Correcao segunda issue
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.minha_vpc.id
  
  tags = {
    Name = "my-iac-sg"
  }
}

## Cria subnet privada na us-east-1a
resource "aws_subnet" "private_subnet_1a" {
  vpc_id            = aws_vpc.minha_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "priv-subnet-1A"
  }
}

## Cria a tabela de rota da subnet privada 1a
resource "aws_route_table" "priv_rt_1a" {
  vpc_id = aws_vpc.minha_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1a.id
  }
  

  tags = {
    Name = "priv-rt-1a"
  }
}

## Associa a rt priv-rt-1a com a subnet privada priv-subnet-1a 
resource "aws_route_table_association" "priv_1a_associate" {
  subnet_id      = aws_subnet.private_subnet_1a.id
  route_table_id = aws_route_table.priv_rt_1a.id
}


## Cria a subnet publica na us-east-1a
resource "aws_subnet" "public_subnet_1a" {
  vpc_id            = aws_vpc.minha_vpc.id
  cidr_block        = "10.0.100.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "pub-subnet-1a"
  }
}

## Cria a tabela de rota da subnet publica 1a
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.minha_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

## Associa a rt pub-rt-1a com a subnet publica pub-subnet-1a 
resource "aws_route_table_association" "pub_1a_associate" {
  subnet_id      = aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.public_rt.id
}

## Cria o internet gateway na vpc 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.minha_vpc.id

  tags = {
    Name = "igw-tf-vpc-automation"
  }
}

## Cria um ip publico para o nat-gateway
resource "aws_eip" "nat_gw_ip_1a" {
  domain           = "vpc"
}

## Cria um nat gateway utilizando um ip publico
resource "aws_nat_gateway" "nat_gw_1a" {
  allocation_id = aws_eip.nat_gw_ip_1a.id
  subnet_id     = aws_subnet.public_subnet_1a.id

  tags = {
    Name = "nat-gw-1a"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

##########################################

## Cria subnet privada na us-east-1a
resource "aws_subnet" "private_subnet_1b" {
  vpc_id            = aws_vpc.minha_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "priv-subnet-1b"
  }
}

## Cria a tabela de rota da subnet privada 1a
resource "aws_route_table" "priv_rt_1b" {
  vpc_id = aws_vpc.minha_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1b.id
  }
  

  tags = {
    Name = "priv-rt-1b"
  }
}

## Associa a rt priv-rt-1a com a subnet privada priv-subnet-1a 
resource "aws_route_table_association" "priv_1b_associate" {
  subnet_id      = aws_subnet.private_subnet_1b.id
  route_table_id = aws_route_table.priv_rt_1b.id
}


## Cria a subnet publica na us-east-1a
resource "aws_subnet" "public_subnet_1b" {
  vpc_id            = aws_vpc.minha_vpc.id
  cidr_block        = "10.0.200.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "pub-subnet-1b"
  }
}


## Associa a rt pub-rt-1a com a subnet publica pub-subnet-1a 
resource "aws_route_table_association" "pub_1b_associate" {
  subnet_id      = aws_subnet.public_subnet_1b.id
  route_table_id = aws_route_table.public_rt.id
}

## Cria um ip publico para o nat-gateway
resource "aws_eip" "nat_gw_ip_1b" {
  domain           = "vpc"
}

## Cria um nat gateway utilizando um ip publico
resource "aws_nat_gateway" "nat_gw_1b" {
  allocation_id = aws_eip.nat_gw_ip_1b.id
  subnet_id     = aws_subnet.public_subnet_1b.id

  tags = {
    Name = "nat-gw-1b"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}





resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.minha_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "alb-sg"
  }
}

resource "aws_security_group" "ec2_sg" {
  name   = "ec2-sg"
  vpc_id = aws_vpc.minha_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  name   = "rds-sg"
  vpc_id = aws_vpc.minha_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false               # false = público
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_subnet.public_subnet_1a.id,
    aws_subnet.public_subnet_1b.id
  ]

  tags = {
    Name = "app-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.minha_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_db_instance" "app_db" {
  identifier = "app-db"

  engine         = "postgres"
  engine_version = "18.1"
  instance_class = "db.t3.micro" # barato p/ lab

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "appdb"
  username = "adminuser"
  password = "SenhaMuitoSegura123!"

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  multi_az = true # PROD-like
  publicly_accessible = false

  skip_final_snapshot = true

  tags = {
    Name = "app-db"
  }
}
