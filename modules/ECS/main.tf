resource "aws_ecs_cluster" "ECSCluster" {
  name = var.ClusterName
}

resource "aws_ecs_task_definition" "JenkinsTaskDefinition" {
  family                   = "jenkins-task"
  task_role_arn            = var.ECSTaskRole.arn
  execution_role_arn       = var.ECSExecutionRole.arn
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  requires_compatibilities = ["FARGATE", "EC2"]

  depends_on = [var.CloudwatchLogsGroup, var.CloudwatchLogsAgent]

  volume {
    name = "jenkins-home"

    efs_volume_configuration {
      file_system_id     = var.FileSystemResource.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = var.AccessPointResource.id
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
        awslogs-region        = var.RegionName
        awslogs-stream-prefix = "jenkins"
      }
    }


    environment = [
      { "name" : "AGENT_EXECUTION_ROLE_ARN", "value" : var.ECSExecutionRole.arn },
      { "name" : "AGENT_SECURITY_GROUP_ID", "value" : var.JenkinsAgentSecurityGroup.id}, 
      { "name" : "AWS_REGION", "value" : var.RegionName },
      { "name" : "ECS_AGENT_CLUSTER", "value" : var.ClusterName },
      { "name" : "JENKINS_URL", "value" : format("%s/", var.JenkinsURL) },
      { "name" : "LOG_GROUP_NAME", "value" : var.CloudwatchLogsAgent.name },
      { "name" : "PRIVATE_JENKINS_HOST_AND_PORT", "value" : format("%s.%s:50000", var.discovery_service.name, var.Namespace) },
      { "name" : "SUBNET_IDS", "value" : join(", ", var.private_subnet_ids) },

      { "name" : "JENKINS_USERNAME", "value" : var.JenkinsUsername }
    ]

    secrets = [{
      name : "JENKINS_PASSWORD",
      valueFrom : var.jenkins_password.arn
    }]
  }])
}


resource "aws_ecs_service" "JenkinsService" {
  name                               = "JenkinsService"
  depends_on                         = [var.LoadBalancerListenerHTTPS]
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
    subnets          = var.private_subnet_ids
    security_groups  = [var.JenkinsSecurityGroup.id , var.EFS_SecurityGroup.id, var.JenkinsAgentSecurityGroup.id]
  }
  

  load_balancer {
    target_group_arn = var.JenkinsTargetGroup.arn
    container_name   = "jenkins"
    container_port   = 8080
  }

  service_registries {
    registry_arn = var.discovery_service.arn
    port         = var.JenkinsJNLPPort
  }
}