variable "vpc_id" {
  type        = string
  description = "VPC hosting the ALB"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private Subnet Ids for NLB. These should be the same AZs the ALB is using."
}

variable "alb_arn" {
  type        = string
  description = "Application Load Balancer ARN"
}

variable "zone_id" {
  type        = string
  description = "Hosted Zone ID"
}

variable "domain_name" {
  type        = string
  description = "Domain Name"
}