
# TERRAFORM
terraform {
  required_version = ">= 0.12"
}


# PROVIDER DETAILS
provider "aws" {
  region     = var.Region
  access_key = var.AccessKey
  secret_key = var.SecretKey

  default_tags {
    tags = {
      CreatedBy = "Terraform"
      Project   = "CICD"
    }
  }
}


# LOCAL VARIABLES
locals {
  policy_resource          = format("arn:aws:elasticfilesystem:%s:%s:file-system/%s", data.aws_region.current.name, data.aws_caller_identity.current.account_id, module.EFS.FileSystemResource.id)
  cluster_resource         = format("arn:aws:ecs:%s:%s:cluster/%s", data.aws_region.current.name, data.aws_caller_identity.current.account_id, var.ClusterName)
  task_definition_resource = format("arn:aws:ecs:%s:%s:task-definition/*", data.aws_region.current.name, data.aws_caller_identity.current.account_id)
  task_resource            = format("arn:aws:ecs:%s:%s:task/*", data.aws_region.current.name, data.aws_caller_identity.current.account_id)

  AZ_Names           = slice(data.aws_availability_zones.AZ.names, 0, var.How_Many_AvailabilityZones)
  public_subnet_ids  = module.VPC.public_subnet_ids
  private_subnet_ids = module.VPC.private_subnet_ids
  vpc_id             = module.VPC.VPC_id
  EFS_SecurityGroup  = module.EFS.EFS_SecurityGroup
}


# DATA
data "aws_availability_zones" "AZ" { state = "available" }
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_secretsmanager_secret" "get_jenkins_password_arn" { arn = module.SecretsManager.JenkinsPassword.arn }
data "aws_secretsmanager_secret_version" "get_jenkins_password_string" { secret_id = data.aws_secretsmanager_secret.get_jenkins_password_arn.id }


# CALL MODULES
module "VPC" {
  source                = "./modules/VPC"
  AZ_Names              = local.AZ_Names
  route53_zone_id       = var.route53_zone_id
  route53_alias_name    = var.route53_alias_name
  CertificateArn        = var.CertificateArn
  JenkinsTargetGroupArn = aws_lb_target_group.JenkinsTargetGroup.arn
}

module "EFS" {
  source                 = "./modules/EFS"
  vpc_id                 = local.vpc_id
  AZ_Names               = local.AZ_Names
  JenkinsSecurityGroupId = [aws_security_group.JenkinsSecurityGroup.id]
  public_subnets         = local.public_subnet_ids
  private_subnets        = local.private_subnet_ids
}

module "DiscoveryService" {
  source        = "./modules/Discovery-Service"
  vpc_id        = local.vpc_id
  Namespace     = var.Namespace
  DiscoveryName = var.DiscoveryName
}

module "SecretsManager" {
  source     = "./modules/Secrets-Manager"
  secret_key = "JenkinsPassword"
}

module "IAMRoles" {
  source                   = "./modules/IAM-Roles"
  policy_resource          = local.policy_resource
  task_resource            = local.task_resource
  task_definition_resource = local.task_definition_resource
  cluster_resource         = local.cluster_resource
  jenkins_password         = module.SecretsManager.JenkinsPassword
}

#-------------------------------------------------------------------------------


resource "aws_security_group_rule" "JenkinsEgress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.JenkinsSecurityGroup.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_lb_target_group" "JenkinsTargetGroup" {
  health_check {
    enabled = true
    path    = "/login"
  }

  name                 = "JenkinsTargetGroup"
  port                 = 8080
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = local.vpc_id
  deregistration_delay = 10
}

resource "aws_security_group" "JenkinsSecurityGroup" {
  name   = "JenkinsSecurityGroup"
  vpc_id = local.vpc_id
}


resource "aws_security_group_rule" "JenkinsAgentEgress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "-1"
  security_group_id = aws_security_group.JenkinsAgentSecurityGroup.id
}



resource "aws_security_group_rule" "EFSJenkinsIngress" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  security_group_id = aws_security_group.JenkinsSecurityGroup.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "JenkinsIngress" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = aws_security_group.JenkinsSecurityGroup.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "JenkinsAgentIngress" {
  type              = "ingress"
  from_port         = var.JenkinsJNLPPort
  to_port           = var.JenkinsJNLPPort
  protocol          = "tcp"
  security_group_id = aws_security_group.JenkinsAgentSecurityGroup.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "JenkinsMasterIngress" {
  type              = "ingress"
  from_port         = var.JenkinsJNLPPort
  to_port           = var.JenkinsJNLPPort
  protocol          = "tcp"
  security_group_id = aws_security_group.JenkinsSecurityGroup.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_ecs_cluster" "ECSCluster" {
  name = var.ClusterName
}


resource "aws_cloudwatch_log_group" "CloudwatchLogsGroup" {
  name              = "CloudwatchLogsGroup"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "CloudwatchLogsAgent" {
  name              = "CloudwatchLogsAgent"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "JenkinsTaskDefinition" {
  family                   = "jenkins-task"
  task_role_arn            = module.IAMRoles.ECSTaskRole.arn
  execution_role_arn       = module.IAMRoles.ECSExecutionRole.arn
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  requires_compatibilities = ["FARGATE", "EC2"]

  depends_on = [aws_cloudwatch_log_group.CloudwatchLogsGroup, aws_cloudwatch_log_group.CloudwatchLogsAgent]

  volume {
    name = "jenkins-home"

    efs_volume_configuration {
      file_system_id     = module.EFS.FileSystemResource.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = module.EFS.AccessPointResource.id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([{
    name  = "jenkins"
    image = "tkgregory/jenkins-ecs-agents:latest"

    portMappings = [
      { containerPort = 8080 },
      { containerPort = var.JenkinsJNLPPort }
    ]

    mountPoints = [
      {
        ContainerPath = "/var/jenkins_home"
        sourceVolume  = "jenkins-home"
      }
    ]

    logConfiguration = {
      LogDriver = "awslogs"
      Options = {
        awslogs-group         = "CloudwatchLogsGroup"
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "jenkins"
      }
    }


    environment = [
      { "name" : "AGENT_EXECUTION_ROLE_ARN", "value" : module.IAMRoles.ECSExecutionRole.arn },
      { "name" : "AGENT_SECURITY_GROUP_ID", "value" : aws_security_group.JenkinsAgentSecurityGroup.id },
      { "name" : "AWS_REGION", "value" : data.aws_region.current.name },
      { "name" : "ECS_AGENT_CLUSTER", "value" : var.ClusterName },
      { "name" : "JENKINS_URL", "value" : format("%s/", var.JenkinsURL) },
      { "name" : "LOG_GROUP_NAME", "value" : aws_cloudwatch_log_group.CloudwatchLogsAgent.name },
      { "name" : "PRIVATE_JENKINS_HOST_AND_PORT", "value" : format("%s.%s:50000", module.DiscoveryService.DiscoveryService.name, var.Namespace) },
      { "name" : "SUBNET_IDS", "value" : join(", ", local.private_subnet_ids) },

      { "name" : "JENKINS_USERNAME", "value" : var.JenkinsUsername }
    ]

    secrets = [{
      name : "JENKINS_PASSWORD",
      valueFrom : module.SecretsManager.JenkinsPassword.arn
    }]
  }])
}


resource "aws_ecs_service" "JenkinsService" {
  name                               = "JenkinsService"
  depends_on                         = [module.VPC.LoadBalancerListenerHTTPS]
  cluster                            = aws_ecs_cluster.ECSCluster.arn
  task_definition                    = aws_ecs_task_definition.JenkinsTaskDefinition.arn
  desired_count                      = 1
  health_check_grace_period_seconds  = 300
  launch_type                        = "FARGATE"
  platform_version                   = "1.4.0"
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  network_configuration {
    assign_public_ip = true
    subnets          = local.private_subnet_ids
    security_groups  = [aws_security_group.JenkinsSecurityGroup.id, local.EFS_SecurityGroup.id, aws_security_group.JenkinsAgentSecurityGroup.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.JenkinsTargetGroup.arn
    container_name   = "jenkins"
    container_port   = 8080
  }

  service_registries {
    registry_arn = module.DiscoveryService.DiscoveryService.arn
    port         = var.JenkinsJNLPPort
  }
}


resource "aws_security_group" "JenkinsAgentSecurityGroup" {
  name   = "JenkinsAgentSecurityGroup"
  vpc_id = local.vpc_id
}



