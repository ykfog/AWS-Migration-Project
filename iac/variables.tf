# =============================================================================
# Input variables
# Secrets (db_password) have NO default and are NOT committed. Supply them via
# terraform.tfvars (git-ignored) or the TF_VAR_db_password environment variable.
# =============================================================================

variable "region" {
  description = "AWS region. AWS Academy sandbox must use us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix applied to resource names/tags."
  type        = string
  default     = "mmu-cloudsec"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Two Availability Zones used for high availability."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "app_port" {
  description = "Port the Node.js application listens on behind the ALB."
  type        = number
  default     = 3000
}

variable "instance_type" {
  description = "EC2 instance type for the application tier."
  type        = string
  default     = "t3.micro"
}

variable "instance_profile_name" {
  description = <<-EOT
    Name of the pre-existing IAM instance profile to attach to the EC2 instances.
    In the AWS Academy sandbox you CANNOT create IAM roles, but a role is provided.
    Verify the exact name in the IAM console (commonly "LabInstanceProfile").
  EOT
  type        = string
  default     = "LabInstanceProfile"
}

variable "db_username" {
  description = "Master username for the RDS MySQL instance."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for RDS. Supply via terraform.tfvars or TF_VAR_db_password. Never commit this."
  type        = string
  sensitive   = true
  # No default on purpose — forces a deliberate, uncommitted value.
}

variable "multi_az" {
  description = "Enable RDS Multi-AZ. true matches the Part B design (costs more)."
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "Globally-unique S3 bucket name. Append a student ID to keep it unique."
  type        = string
  default     = "mmu-assignment2-storage-grp1"
}

variable "enable_waf" {
  description = "Attach an AWS WAFv2 web ACL to the ALB. Disable if the sandbox blocks WAFv2."
  type        = bool
  default     = true
}

variable "enable_https" {
  description = <<-EOT
    Add a self-signed HTTPS:443 listener to the ALB. Requires acm:ImportCertificate,
    which may be blocked in the AWS Academy sandbox (like RDS/WAF). Default false so a
    plain apply is unaffected; set true to attempt the HTTPS listener.
  EOT
  type        = bool
  default     = false
}
