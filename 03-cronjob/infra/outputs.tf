output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = module.daily_files_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.daily_files_bucket.s3_bucket_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda_daily_file.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda_daily_file.lambda_function_arn
}

output "eventbridge_schedule_arn" {
  description = "ARN of the EventBridge schedule"
  value       = module.eventbridge_schedule.eventbridge_schedule_arns["daily-file-inserter"]
}