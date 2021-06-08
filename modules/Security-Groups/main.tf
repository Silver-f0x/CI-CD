resource "aws_security_group" "JenkinsSecurityGroup" {
  name   = "JenkinsSecurityGroup"
  vpc_id = var.vpc_id
}


resource "aws_security_group_rule" "JenkinsAgentEgress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "-1"
  security_group_id = aws_security_group.JenkinsAgentSecurityGroup.id
}

resource "aws_security_group_rule" "JenkinsEgress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.JenkinsSecurityGroup.id
  cidr_blocks       = ["0.0.0.0/0"]
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

resource "aws_security_group" "JenkinsAgentSecurityGroup" {
  name   = "JenkinsAgentSecurityGroup"
  vpc_id = var.vpc_id
}
