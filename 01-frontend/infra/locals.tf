locals {
  bucket_name_prefix = "sioeuzal-frontend"
  bucket_name        = "${local.bucket_name_prefix}-${data.aws_caller_identity.current.account_id}"

  environment = var.environment

  s3_bucket_regional_domain_name = "${local.bucket_name}.s3.${var.region}.amazonaws.com"


  tags = {
    Environment = local.environment
    Project     = "DreamSquad"
    Owner       = "Louise Souza"
  }
}