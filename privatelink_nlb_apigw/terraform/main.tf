resource "aws_lb" "this" {
  #checkov:skip=CKV_AWS_152:Cross-zone load balancing is disabled
  #checkov:skip=CKV_AWS_91:Disabled access logging

  load_balancer_type = "network"
  internal           = true
  ip_address_type    = "ipv4"

  enable_deletion_protection = true

  subnets = var.subnet_ids
}

resource "aws_lb_target_group" "this" {
  target_type = "ip"
  port        = 443
  protocol    = "TLS"
  vpc_id      = var.vpc_id

  preserve_client_ip     = true
  deregistration_delay   = 0
  connection_termination = true
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = toset(data.dns_a_record_set.vpce.addrs)

  target_group_arn = aws_lb_target_group.this.arn
  target_id        = each.value
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "4.3.2"

  domain_name = var.domain_name
  zone_id     = var.zone_id

  wait_for_validation = true

  tags = {
    Name = var.domain_name
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  certificate_arn   = module.acm.acm_certificate_arn
  port              = 443
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-3-2021-06"
  alpn_policy       = "HTTP1Only"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_sns_topic" "this" {
  display_name      = "VPC Endpoint Notifications"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_policy" "this" {
  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_vpc_endpoint_service" "this" {
  #checkov:skip=CKV_AWS_123:Disabled manual acceptance

  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.this.arn]
  private_dns_name           = var.domain_name
  supported_ip_address_types = ["ipv4"]
}

resource "aws_vpc_endpoint_connection_notification" "this" {
  vpc_endpoint_service_id     = aws_vpc_endpoint_service.this.id
  connection_notification_arn = aws_sns_topic.this.arn
  connection_events           = ["Accept", "Reject", "Connect", "Delete"]
}

resource "aws_route53_record" "this" {
  zone_id = var.zone_id
  name    = "${aws_vpc_endpoint_service.this.private_dns_name_configuration[0].name}.${var.domain_name}"
  records = [aws_vpc_endpoint_service.this.private_dns_name_configuration[0].value]
  type    = aws_vpc_endpoint_service.this.private_dns_name_configuration[0].type
  ttl     = 1800
}