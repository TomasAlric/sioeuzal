locals {
  project_name = "sioeuzal"
  environment  = var.environment

  repo_name    = "${local.project_name}-${data.aws_caller_identity.current.account_id}"
  cluster_name = "${local.project_name}-cluster-${data.aws_caller_identity.current.account_id}"

  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]

  tags = {
    Project     = local.project_name
    Environment = local.environment
    Terraform   = "true"
    Module      = "backend"
  }
}