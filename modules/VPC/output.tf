output "public_subnet_ids" {
  value = [for k, v in aws_subnet.public_subnet : v.id]
}

output "private_subnet_ids" {
  value = [for k, v in aws_subnet.private_subnet : v.id]
}

output "private_subnet" {
  value = aws_subnet.private_subnet
}

output "VPC_id" {
  value = aws_vpc.main.id
}

output "LoadBalancerListenerHTTPS" {
  value = aws_lb_listener.LoadBalancerListenerHTTPS
}

output "LoadBalancer" {
  value = aws_lb.LoadBalancer
}