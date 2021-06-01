output "JenkinsPassword" {
  value = aws_secretsmanager_secret.PasswordSecret
}