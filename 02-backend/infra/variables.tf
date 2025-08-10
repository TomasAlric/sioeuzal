variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "ecs_service_desired_count" {
  description = "Desired number of ECS service tasks"
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 5000
}

variable "container_cpu" {
  description = "CPU units for the container (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "container_memory" {
  description = "Memory in MB for the container"
  type        = number
  default     = 1024
}

variable "logs_retention_days" {
  description = "Number of days to retain logs in CloudWatch"
  type        = number
  default     = 30
}
