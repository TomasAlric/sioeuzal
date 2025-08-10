locals {
  bucket_name_prefix = "sioeuzal-cronjob"
  bucket_name        = "${local.bucket_name_prefix}-${data.aws_caller_identity.current.account_id}"

  environment = var.environment
  region      = var.region

  lambda_name        = "daily-file-inserter"
  lambda_description = "Lambda to upload file with date/time to S3 daily"

  schedule_name        = "daily-file-inserter"
  schedule_description = "Runs every day at 10:00 AM"
  schedule_expression  = "cron(0 13 * * ? *)"

  tags = {
    Environment = local.environment
    Project     = "DreamSquad"
    Owner       = "Louise Souza"
    Service     = "cronjob"
    Terraform   = "true"
    Schedule    = "daily-10am"
  }
}
