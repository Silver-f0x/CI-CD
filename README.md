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


# Variables
| Variable  | Description | Type | Default | Required
| ------------- | ------------- |
| Region  | Which AWS region to build the infrastructure | String | US East 1 | No |
| CertificateArn | An ARN for your SSL certificate | String | N/A | Yes | 
| ClusterName | What to name your ECS cluster | String | default-cluster | No |
| JenkinsJNLPPort | Which JNLP Port Jenkins should use | Number | 50000 | No |
| JenkinsUsername | Which username to login to Jenkins with | String | developer | No |
| JenkinsURL | Which URL should redirect to the Jenkins master | String | N/A | Yes |
| NameSpace | The NameSpace for Jenkins in the discovery service | String | discoverjenkins | No |
| DiscoveryName | The name for Jenkins in the discovery service | String | jenkins | No |
| route53_alias_name | The alias name for Jenkins in DNS | String | N/A | Yes |
| How_Many_AvailabilityZones | How many Availability Zones your infrastructure should be spread across for reliability (minimum 2) | Number | 2 | No |

