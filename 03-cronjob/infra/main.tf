module "daily_files_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.3.1"

  bucket = local.bucket_name

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  force_destroy = true

  versioning = {
    enabled = true
  }

  lifecycle_rule = [
    {
      id      = "cleanup"
      enabled = true
      expiration = {
        days = 30
      }
    }
  ]

  tags = local.tags
}

module "lambda_daily_file" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.0.1"

  function_name = local.lambda_name
  description   = local.lambda_description
  handler       = var.handler
  runtime       = var.runtime

  source_path = "../app/src"

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  environment_variables = {
    BUCKET_NAME = local.bucket_name
    REGION      = var.region
  }

  cloudwatch_logs_retention_in_days = var.logs_retention_days

  tags = local.tags
}

resource "aws_iam_role_policy" "lambda_s3_write" {
  name = "${local.lambda_name}-s3-write"
  role = module.lambda_daily_file.lambda_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.daily_files_bucket.s3_bucket_arn,
          "${module.daily_files_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })

  depends_on = [module.lambda_daily_file]
}

module "eventbridge_schedule" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.1.0"

  create_bus = false

  attach_lambda_policy = true
  lambda_target_arns   = [module.lambda_daily_file.lambda_function_arn]

  schedules = {
    daily-file-inserter = {
      name                = local.schedule_name
      description         = local.schedule_description
      schedule_expression = var.schedule_expression
      timezone            = "America/Sao_Paulo"
      arn                 = module.lambda_daily_file.lambda_function_arn
      input               = jsonencode({ "job" : "daily_s3_upload" })
    }
  }

  tags = local.tags
}

resource "aws_lambda_permission" "allow_eventbridge_scheduler" {
  statement_id  = "AllowExecutionFromEventBridgeScheduler"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_daily_file.lambda_function_name
  principal     = "scheduler.amazonaws.com"
  source_arn = module.eventbridge_schedule.eventbridge_schedules["daily-file-inserter"].arn
}