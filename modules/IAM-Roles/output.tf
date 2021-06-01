
output "ECSTaskRole" {
  value = aws_iam_role.ECSTaskRole
}

output "ECSExecutionRole" {
  value = aws_iam_role.ECSExecutionRole
}