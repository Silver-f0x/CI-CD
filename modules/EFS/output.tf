output "FileSystemResource" {
  value = aws_efs_file_system.FileSystemResource
}

output "AccessPointResource" {
  value = aws_efs_access_point.AccessPointResource
}

output "EFS_SecurityGroup" {
  value = aws_security_group.EFSSecurityGroup
}