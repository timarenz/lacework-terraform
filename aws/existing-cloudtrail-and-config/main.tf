provider "aws" {
  region = var.aws_default_region
}

provider "lacework" {}

data "aws_caller_identity" "current" {}

data "aws_s3_bucket" "existing" {
  bucket = var.existing_s3_bucket
}

resource "random_id" "id" {
  byte_length = 3
}

module "lacework_aws_iam" {
  source  = "lacework/iam-role/aws"
  version = "~> 0.2.2"

  iam_role_name = "lacework-security-audit-${random_id.id.hex}"
  tags = {
    "environment" = var.environment_name
    "owner"       = var.owner_name
  }
}

module "lacework_aws_config" {
  source  = "lacework/config/aws"
  version = "~> 0.4.1"

  depends_on = [
    module.lacework_aws_iam
  ]

  lacework_integration_name  = "aws-config-${data.aws_caller_identity.current.account_id}-${random_id.id.hex}"
  use_existing_iam_role      = true
  iam_role_name              = module.lacework_aws_iam.name
  iam_role_arn               = module.lacework_aws_iam.arn
  iam_role_external_id       = module.lacework_aws_iam.external_id
  lacework_audit_policy_name = "lwaudit-policy-${var.environment_name}${random_id.id.hex}"
  tags = {
    "environment" = var.environment_name
    "owner"       = var.owner_name
  }
}

module "lacework_aws_cloudtrail" {
  source  = "lacework/cloudtrail/aws"
  version = "~> 0.5.0"

  depends_on = [
    module.lacework_aws_iam
  ]

  lacework_integration_name = "aws-cloudtrail-${data.aws_caller_identity.current.account_id}-${random_id.id.hex}"
  use_existing_iam_role     = true
  iam_role_name             = module.lacework_aws_iam.name
  iam_role_arn              = module.lacework_aws_iam.arn
  iam_role_external_id      = module.lacework_aws_iam.external_id
  use_existing_cloudtrail   = true
  bucket_name               = data.aws_s3_bucket.existing.bucket
  bucket_arn                = data.aws_s3_bucket.existing.arn
  prefix                    = lower("lacework-ct-${var.environment_name}-${random_id.id.hex}")
  tags = {
    "environment" = var.environment_name
    "owner"       = var.owner_name
  }
}
