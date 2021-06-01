
# IAM - ECS Execution Role
resource "aws_iam_role" "ECSExecutionRole" {
  name = "jenkins-execution-role"
  path = "/"

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}


# IAM - ECS Execution Role Policies
resource "aws_iam_role_policy" "secretaccess" {
  name   = "secretaccess"
  role   = aws_iam_role.ECSExecutionRole.id
  policy = <<-JSON
  {
    "Version": "2012-10-17",
    "Statement": {
      "Action": "secretsmanager:GetSecretValue",
      "Effect": "Allow",
      "Resource": "${var.jenkins_password.arn}"
    }
  }
  JSON
}


# IAM - ECS Task Role
resource "aws_iam_role" "ECSTaskRole" {
  name = "ECSTaskExecution"
  path = "/"

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}


# IAM - ECS Task Role Policies
resource "aws_iam_role_policy" "create-jenkins-agents" {
  name   = "create-jenkins-agents3"
  role   = aws_iam_role.ECSTaskRole.id
  policy = <<-JSON
  {
    "Version": "2012-10-17",
    "Statement": [
      {
      "Action": ["ecs:RegisterTaskDefinition", "ecs:ListClusters", "ecs:DescribeContainerInstances", "ecs:ListTaskDefinitions", "ecs:DescribeTaskDefinition", "ecs:DeregisterTaskDefinition"],
      "Effect": "Allow",
      "Resource": "*"
      },
      {
      "Action": "ecs:ListContainerInstances",
      "Effect": "Allow",
      "Resource": "${var.cluster_resource}"
      },
      {
      "Action": "ecs:RunTask",
      "Effect": "Allow",
      "Condition": {"ArnEquals": {"ecs:cluster": "${var.cluster_resource}"}},
      "Resource": "${var.task_definition_resource}"
      },
      {
      "Action": "ecs:StopTask",
      "Effect": "Allow",
      "Condition": {"ArnEquals": {"ecs:cluster": "${var.cluster_resource}"}},
      "Resource": "${var.task_resource}"
      },
      {
      "Action": "ecs:DescribeTasks",
      "Effect": "Allow",
      "Condition": {"ArnEquals": {"ecs:cluster": "${var.cluster_resource}"}},
      "Resource": "${var.task_resource}"
      },
      {
      "Action": ["iam:GetRole", "iam:PassRole"],
      "Effect": "Allow",
      "Resource": "${aws_iam_role.ECSExecutionRole.arn}"
      }
    ]
  }
  JSON
}


# IAM - EFS Role
resource "aws_iam_role_policy" "EFS" {
  name   = "EFS-Role"
  role   = aws_iam_role.ECSTaskRole.id
  policy = <<-JSON
  {
    "Version": "2012-10-17",
    "Statement": {
      "Action": ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientWrite"],
      "Effect": "Allow",
      "Resource": "${var.policy_resource}"
    }
  }
  JSON
}