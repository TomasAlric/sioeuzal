module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name = "${local.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = local.availability_zones
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  create_igw = true

  tags = local.tags
}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.4.0"

  repository_image_tag_mutability = "MUTABLE"

  repository_name = local.repo_name

  repository_force_delete = true
  
  repository_read_write_access_arns = [data.aws_caller_identity.current.arn]

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 3 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 3
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = local.tags
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.2.1"

  cluster_name = local.cluster_name

  services = {
    backend-service = {
      launch_type = "FARGATE"
      cpu         = var.container_cpu
      memory      = var.container_memory

      container_definitions = {
        backend-container = {
          image     = "${module.ecr.repository_url}:latest"
          cpu       = var.container_cpu
          memory    = var.container_memory
          essential = true

          portMappings = [
            {
              containerPort = var.container_port
              protocol      = "tcp"
            }
          ]

          environment = [
            {
              name  = "ENVIRONMENT"
              value = var.environment
            },
            {
              name  = "FLASK_APP"
              value = "src/app.py"
            },
            {
              name  = "FLASK_RUN_HOST"
              value = "0.0.0.0"
            },
            {
              name  = "FLASK_RUN_PORT"
              value = "5000"
            },
            {
              name  = "FLASK_ENV"
              value = var.environment
            }
          ]

          healthCheck = {
            command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:5000/health || exit 1"]
            interval    = 30
            timeout     = 3
            retries     = 3
            startPeriod = 60
          }

          logConfiguration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = aws_cloudwatch_log_group.backend_service.name
              awslogs-region        = var.region
              awslogs-stream-prefix = "ecs"
            }
          }
        }
      }

      desired_count = 1

      subnet_ids         = module.vpc.public_subnets
      security_group_ids = [aws_security_group.backend_sg.id]

      assign_public_ip = true
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.backend_service
  ]

  tags = local.tags
}

resource "aws_security_group" "backend_sg" {
  name        = "${local.project_name}-backend-sg"
  description = "Security group for the backend service"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow traffic on the container port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.tags, {
    Name = "${local.project_name}-backend-sg"
  })
}

resource "aws_cloudwatch_log_group" "backend_service" {
  name              = "/aws/ecs/${local.cluster_name}/backend-service"
  retention_in_days = 30
  tags              = local.tags
}