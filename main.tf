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

resource "aws_key_pair" "lab" {
  key_name   = "terraform-lab"
  public_key = file("~/.ssh/id_rsa.pub")
}

variable "key_name" {
  type        = string
  default     = "terraform-lab"
  description = "terraform-lab"
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
  engine_version = "16" # Ajustado para uma versão compatível por padrão (16)
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "appdb"
  username = "adminuser"
  password = "SenhaMuitoSegura123!"

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # --- MUDANÇAS PARA VELOCIDADE ---
  
  # 1. Desative Multi-AZ. Isso corta o tempo de criação pela metade.
  multi_az = false 

  # 2. Desative backups automáticos. Evita que o RDS fique fazendo backup logo após ligar.
  backup_retention_period = 0 

  # 3. Permite acesso público? Se for false, certifique-se que está acessando via EC2/VPN.
  publicly_accessible = false

  # 4. Pula snapshot final ao destruir (já estava true, mantive).
  skip_final_snapshot = true

  # 5. Aplica qualquer mudança imediatamente sem esperar janela de manutenção.
  apply_immediately = true

  tags = {
    Name = "app-db"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}


resource "aws_instance" "app_1a" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_subnet_1a.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name      = var.key_name

  user_data = <<EOF
#!/bin/bash
yum install -y httpd
systemctl enable httpd
systemctl start httpd
echo "EC2 1A OK" > /var/www/html/index.html
EOF

  tags = {
    Name = "app-1a"
  }
}

resource "aws_instance" "app_1b" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_subnet_1b.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name      = var.key_name

  user_data = <<EOF
#!/bin/bash
yum install -y httpd
systemctl enable httpd
systemctl start httpd
echo "EC2 1B OK" > /var/www/html/index.html
EOF

  tags = {
    Name = "app-1b"
  }
}












resource "aws_lb_target_group_attachment" "tg_1a" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_1a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg_1b" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_1b.id
  port             = 80
}

resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(file("${path.module}/script/node_exporter.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "app-node"
      Monitoring  = "node-exporter"
    }
  }
}







# CloudFront Distribution
resource "aws_cloudfront_distribution" "app_distribution" {
  origin {
    domain_name = aws_lb.app_alb.dns_name
    origin_id   = "alb-origin"

    custom_header {
      name  = "User-Agent"
      value = "CloudFront"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = ""

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb-origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }

      headers = ["Host"]
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # Cache behavior for static assets
  ordered_cache_behavior {
    path_pattern     = "/static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb-origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "app-cloudfront-distribution"
  }

  depends_on = [aws_lb.app_alb]
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.app_distribution.domain_name
  description = "CloudFront domain name para acessar a aplicação"
}

# Elastic IP para ALB
resource "aws_eip" "alb_eip" {
  domain = "vpc"

  tags = {
    Name = "alb-eip"
  }

  depends_on = [aws_internet_gateway.igw]
}

output "alb_elastic_ip" {
  value       = aws_eip.alb_eip.public_ip
  description = "IP Elástico do ALB"
}

output "alb_dns_name" {
  value       = aws_lb.app_alb.dns_name
  description = "DNS name do ALB"
}
