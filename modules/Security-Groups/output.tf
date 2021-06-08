output "JenkinsSecurityGroup" {
  value = aws_security_group.JenkinsSecurityGroup
}

output "JenkinsAgentSecurityGroup" {
  value = aws_security_group.JenkinsAgentSecurityGroup
}