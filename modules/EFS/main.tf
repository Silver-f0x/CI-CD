

# EFS - File System
resource "aws_efs_file_system" "FileSystemResource" {
  encrypted = true
}


# EFS - Security Group
resource "aws_security_group" "EFSSecurityGroup" {
  name   = "EFSSecurityGroup"
  vpc_id = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    security_groups = [var.JenkinsSecurityGroupId[0]]
  }
}


# EFS - Security Group Rules
resource "aws_security_group_rule" "EFSEgress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.EFSSecurityGroup.id
  cidr_blocks       = ["0.0.0.0/0"]
}


# EFS - Mount Targets
resource "aws_efs_mount_target" "MountTargetResource" {
  count           = length(var.AZ_Names)
  file_system_id  = aws_efs_file_system.FileSystemResource.id
  subnet_id       = var.private_subnets[count.index]
  security_groups = [aws_security_group.EFSSecurityGroup.id]
  depends_on      = [var.private_subnets]
}


# EFS - Access Point
resource "aws_efs_access_point" "AccessPointResource" {
  file_system_id = aws_efs_file_system.FileSystemResource.id

  posix_user {
    uid = "1000"
    gid = "1000"
  }

  root_directory {
    path = "/jenkins-home"
    creation_info {
      owner_gid   = "1000"
      owner_uid   = "1000"
      permissions = "755"
    }
  }
}