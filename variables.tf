

variable "Region" {
  type    = string
  default = "us-east-1"
}

variable "AccessKey" {
  type    = string
}

variable "SecretKey" {
  type    = string
}

variable "CertificateArn" {
  type    = string
  default = "arn:aws:acm:us-east-1:363815587338:certificate/2a1b71be-bb52-4386-a217-2385e282c2d4"
}

variable "ClusterName" {
  type    = string
  default = "default-cluster"
}

variable "JenkinsJNLPPort" {
  type    = number
  default = 50000
}

variable "JenkinsUsername" {
  type    = string
  default = "developer"
}

variable "JenkinsURL" {
  type    = string
  default = "https://jenkins.allenmitchell.net"
}

variable "Namespace" {
  type    = string
  default = "discoverjenkins"
}

variable "DiscoveryName" {
  type    = string
  default = "jenkins"
}

variable "route53_zone_id" {
  type    = string
  default = "Z03479822DKZ88ORA866O"  Z03479822DKZ88ORA8660
}

variable "route53_alias_name" {
  type    = string
  default = "jenkins"
}

variable "How_Many_AvailabilityZones" {
  type    = number
  default = 2
}