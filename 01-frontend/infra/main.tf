module "frontend_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.3.1"

  bucket                   = local.bucket_name
  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  force_destroy = true

  versioning = {
    enabled = true
  }

  website = {
    index_document = "index.html"
  }
}

module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "5.0.0"

  comment         = "CloudFront with OAC for S3"
  enabled         = true
  price_class     = "PriceClass_All"
  is_ipv6_enabled = true

  create_origin_access_control  = true
  create_origin_access_identity = false

  origin_access_control = {
    s3 = {
      description      = "OAC for S3 bucket"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3_one = {
      domain_name              = local.s3_bucket_regional_domain_name
      origin_access_control_id = module.cdn.cloudfront_origin_access_controls_ids[0]
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3_one"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = false
  }

  viewer_certificate = {
    cloudfront_default_certificate = true
  }

  default_root_object = "index.html"

  tags = local.tags
}

resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = module.frontend_bucket.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${module.frontend_bucket.s3_bucket_id}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${module.cdn.cloudfront_distribution_id}"
          }
        }
      }
    ]
  })

  depends_on = [module.cdn, module.frontend_bucket]
}
