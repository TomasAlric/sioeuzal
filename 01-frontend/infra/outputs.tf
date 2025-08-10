output "bucket_name" {
  description = "S3 bucket name"
  value       = module.frontend_bucket.s3_bucket_id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.frontend_bucket.s3_bucket_arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cdn.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cdn.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = module.cdn.cloudfront_distribution_arn
}