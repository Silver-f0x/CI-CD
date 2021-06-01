variable "AZ_Names" {
  type = list(string)
}

variable "route53_zone_id" {
  type = string
}

variable "route53_alias_name" {
  type = string
}

variable "CertificateArn" {
  type = string
}

variable "JenkinsTargetGroupArn" {
  type = string
}