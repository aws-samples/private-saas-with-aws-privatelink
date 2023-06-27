output "vpc_endpoint_service_id" {
  value = aws_vpc_endpoint_service.this.id
}

output "vpc_endpoint_service_name" {
  value = aws_vpc_endpoint_service.this.service_name
}

output "private_dns_name" {
  value = var.domain_name
}