variable "vpc_id" {
  type        = string
  description = "VPC hosting the ALB"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private Subnet Ids for NLB. These should be the same AZs the private API Gateway is using."
}

variable "vpc_endpoint_id" {
  type        = string
  description = "VPC Endpoint ID for the private API Gateway"
}

variable "zone_id" {
  type        = string
  description = "Hosted Zone ID"
}

variable "domain_name" {
  type        = string
  description = "Domain Name"
}