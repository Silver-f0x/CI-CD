

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
}

variable "route53_alias_name" {
  type    = string
  default = "jenkins"
}

variable "How_Many_AvailabilityZones" {
  type    = number
  default = 2
}