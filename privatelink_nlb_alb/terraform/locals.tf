locals {
  tags = {
    Terraform = "true"
  }

  aws_account_id = data.aws_caller_identity.current.account_id
}