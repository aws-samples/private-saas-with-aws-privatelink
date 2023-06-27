data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["vpce.amazonaws.com"]
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.this.arn]
    effect    = "Allow"

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_vpc_endpoint_service.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.aws_account_id]
    }
  }
}

data "aws_vpc_endpoint" "apigw" {
  id = var.vpc_endpoint_id
}

data "dns_a_record_set" "vpce" {
  host = data.aws_vpc_endpoint.apigw.dns_entry[0].dns_name
}