
# CREATE SECRET KEY
resource "aws_secretsmanager_secret" "PasswordSecret" {
  name                    = var.secret_key
  recovery_window_in_days = 0
}

# GENERATE PASSWORD
resource "random_password" "generated_password" {
  length           = 56
  special          = true
  min_special      = 5
  override_special = "!#$%^&*()-_=+[]{}<>:?"
  keepers = {
    pass_version = 1
  }
}

# SET SECRET VALUE
resource "aws_secretsmanager_secret_version" "generated_password" {
  secret_id     = aws_secretsmanager_secret.PasswordSecret.id
  secret_string = random_password.generated_password.result
  depends_on    = [aws_secretsmanager_secret.PasswordSecret]
}




