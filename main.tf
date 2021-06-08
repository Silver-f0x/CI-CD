
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
  JenkinsSecurityGroupId = [module.SecurityGroups.JenkinsSecurityGroup.id]  
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

module "SecurityGroups" {
  source = "./modules/Security-Groups"
  vpc_id          = local.vpc_id
  JenkinsJNLPPort = var.JenkinsJNLPPort
}

module "ECS" {
  source = "./modules/ECS"
  vpc_id          = local.vpc_id
  discovery_service = module.DiscoveryService.DiscoveryService
  private_subnet_ids = local.private_subnet_ids
  ClusterName = var.ClusterName
  JenkinsSecurityGroup = module.SecurityGroups.JenkinsSecurityGroup
  JenkinsAgentSecurityGroup = module.SecurityGroups.JenkinsAgentSecurityGroup
  EFS_SecurityGroup = module.EFS.EFS_SecurityGroup
  jenkins_password = module.SecretsManager.JenkinsPassword
  JenkinsUsername = var.JenkinsUsername
  JenkinsJNLPPort = var.JenkinsJNLPPort
  JenkinsURL = var.JenkinsURL
  CloudwatchLogsGroup = aws_cloudwatch_log_group.CloudwatchLogsGroup
  CloudwatchLogsAgent = aws_cloudwatch_log_group.CloudwatchLogsAgent
  RegionName = data.aws_region.current.name
  ECSTaskRole = module.IAMRoles.ECSTaskRole
  ECSExecutionRole = module.IAMRoles.ECSExecutionRole
  AccessPointResource = module.EFS.AccessPointResource
  FileSystemResource = module.EFS.FileSystemResource
  Namespace = var.Namespace
  LoadBalancerListenerHTTPS = module.VPC.LoadBalancerListenerHTTPS
  JenkinsTargetGroup = aws_lb_target_group.JenkinsTargetGroup
}

#-------------------------------------------------------------------------------

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

resource "aws_cloudwatch_log_group" "CloudwatchLogsGroup" {
  name              = "CloudwatchLogsGroup"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "CloudwatchLogsAgent" {
  name              = "CloudwatchLogsAgent"
  retention_in_days = 7
}