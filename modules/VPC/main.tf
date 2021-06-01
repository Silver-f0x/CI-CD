

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "VPC"
  }
}


# SUBNETS
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = format("10.0.%s.0/24", index(var.AZ_Names, each.value) + 1)
  map_public_ip_on_launch = true
  for_each                = toset(var.AZ_Names)
  availability_zone       = each.value
  tags = {
    Name = format("PublicSubnet%s", index(var.AZ_Names, each.value) + 1)
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = format("10.0.%s.0/24", length(aws_subnet.public_subnet) + index(var.AZ_Names, each.value) + 1)
  map_public_ip_on_launch = false
  for_each                = toset(var.AZ_Names)
  availability_zone       = each.value
  tags = {
    Name = format("PrivateSubnet%s", index(var.AZ_Names, each.value) + 1)
  }
}


# INTERNET GATEWAY
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "IGW"
  }
}


# NAT GATEWAY
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  for_each   = toset(var.AZ_Names)
  tags = {
    Name = format("NatGW-EIP%s", index(var.AZ_Names, each.value) + 1)
  }
}

resource "aws_nat_gateway" "nat_gw" {
  for_each      = toset(var.AZ_Names)
  subnet_id     = aws_subnet.public_subnet[each.key].id
  allocation_id = aws_eip.nat_eip[each.key].id
  tags = {
    Name = format("NatGW%s", index(var.AZ_Names, each.value) + 1)
  }
}


# PUBLIC ROUTE TABLE
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table_association" "PublicRouteTableSubnetAssociation" {
  for_each       = toset(var.AZ_Names)
  subnet_id      = aws_subnet.public_subnet[each.key].id
  route_table_id = aws_route_table.public_route_table.id
}


# PRIVATE ROUTE TABLE
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  for_each = toset(var.AZ_Names)
  route {
    # DEFAULT PRIVATE ROUTE
    cidr_block = "0.0.0.0/0"
    # NAT GATEWAY
    gateway_id = aws_nat_gateway.nat_gw[each.key].id
  }
  tags = {
    Name = format("PrivateRouteTable%s", index(var.AZ_Names, each.value) + 1)
  }
}

resource "aws_route_table_association" "PrivateRouteTableSubnetAssociation" {
  for_each       = toset(var.AZ_Names)
  subnet_id      = aws_subnet.private_subnet[each.key].id
  route_table_id = aws_route_table.private_route_table[each.key].id
}


# DNS
resource "aws_route53_record" this {
  zone_id = var.route53_zone_id
  name    = var.route53_alias_name
  type    = "A"

  alias {
    name                   = aws_lb.LoadBalancer.dns_name
    zone_id                = aws_lb.LoadBalancer.zone_id
    evaluate_target_health = true
  }
}


# LOAD BALANCER
resource "aws_lb" "LoadBalancer" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.LoadBalancerSecurityGroup.id]
  subnets            = [for k, v in aws_subnet.public_subnet : v.id]
}


# LOAD BALANCER - LISTENERS
resource "aws_lb_listener" "LoadBalancerListenerHTTPS" {
  load_balancer_arn = aws_lb.LoadBalancer.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.CertificateArn

  default_action {
    type             = "forward"
    target_group_arn = var.JenkinsTargetGroupArn
  }
}

resource "aws_lb_listener" "LoadBalancerListenerHTTP" {
  load_balancer_arn = aws_lb.LoadBalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_rule" redirect_http_to_https {
  listener_arn = aws_lb_listener.LoadBalancerListenerHTTP.arn

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    http_header {
      http_header_name = "*"
      values           = ["*"]
    }
  }
}


# LOAD BALANCER - SECURITY GROUP
resource "aws_security_group" "LoadBalancerSecurityGroup" {
  name   = "LoadBalancerSecurityGroup"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "LoadBalancerEgress" {
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.LoadBalancerSecurityGroup.id
}


# LOAD BALANCER - SECURITY GROUP RULES
resource "aws_security_group_rule" "LoadBalancerHTTPSIngress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.LoadBalancerSecurityGroup.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "LoadBalancerHTTPIngress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.LoadBalancerSecurityGroup.id
  cidr_blocks       = ["0.0.0.0/0"]
}