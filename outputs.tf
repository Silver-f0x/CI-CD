
output "LoadBalancerDNS" {
  value = module.VPC.LoadBalancer.dns_name

}

output "JenkinsPassword" {
  value = data.aws_secretsmanager_secret_version.get_jenkins_password_string.secret_string
}