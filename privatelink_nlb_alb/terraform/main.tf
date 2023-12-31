resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow 443/tcp from anywhere"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Allow all traffic to anywhere"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb" "this" {
  #checkov:skip=CKV_AWS_152:Cross-zone load balancing is disabled
  #checkov:skip=CKV_AWS_91:Disabled access logging

  load_balancer_type = "network"
  internal           = true
  ip_address_type    = "ipv4"

  enable_deletion_protection = true

  security_groups = [aws_security_group.allow_tls.id]
  subnets         = var.subnet_ids
}

resource "aws_lb_target_group" "this" {
  target_type = "alb"
  port        = 443
  protocol    = "TCP"
  vpc_id      = var.vpc_id

  health_check {
    protocol = "HTTPS"
  }
}

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = var.alb_arn
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "TCP"

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