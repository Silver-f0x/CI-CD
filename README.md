# AWS CI/CD Pipeline via Jenkins - Terraform Module

Terraform module which creates a Jenkins environment hosted on AWS ECS(Fargate)

It creates the following resources:
* Virtual Private Cloud
  * Customizable number of Availability Zones for reliability
  * Application Load Balancer
  * Subnets (Public & Private)
  * Internet Gateway
  * Nat Gateways
  * Route Tables (Public & Private)
  * Route53 Records
* Jenkins
  * Master (via Docker container hosted on Elastic Container Service (Fargate). While only operating in one AZ at a time, it will recreate in another for disaster recovery )
    * Admin password (generated and stored on Secrets Manager)
  * Slaves (created on demand by the Jenkins Master. Hosted on Elastic Container Service (Fargate). These are spread across multiple AZ )
  * Logging via Cloudwatch
* Application Load Balancer
* Storage for the Jenkins Master (via Elastic File System)
* Discovery Service for Jenkins Master (via Cloud Map)
* IAM Roles for the above
* Security Groups for the above



# Dependencies
An AWS account  
Terraform 13+  
A SSL certificate to use with the Application Load Balancer

