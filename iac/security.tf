# =========================================================================
# 1. SECURE FILE STORAGE BUCKET (Encrypted & TLS Enforced)
# =========================================================================
resource "aws_s3_bucket" "app_bucket" {
  bucket        = "mmu-assignment2-storage-1221101391" 
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encrypt" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms" 
    }
  }
}

resource "aws_s3_bucket_policy" "enforce_tls" {
  bucket = aws_s3_bucket.app_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.app_bucket.arn,
          "${aws_s3_bucket.app_bucket.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}

# =========================================================================
# 2. SECURE, ENCRYPTED RDS MYSQL DATABASE
# =========================================================================
resource "aws_db_instance" "mysql_db" {
  allocated_storage     = 20
  max_allocated_storage = 30
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro" 
  identifier            = "app-primary-db"
  
  db_name               = "app_database"
  username              = "admin"
  password              = "SecurePassword2026!" 
  
  storage_encrypted     = true  
  
  # Note: The assignment Part B Q4 prefers Multi-AZ. 
  # Set to true for final deployment to maximize marks, or keep false for lab testing.
  multi_az              = false 
  skip_final_snapshot   = true

  # CRITICAL: Attach the highly restricted Database Security Group
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

# =========================================================================
# 3. RESTRICTED SECURITY GROUPS (Least Privilege Chain)
# =========================================================================
# Public Facing Load Balancer SG
resource "aws_security_group" "alb_sg" {
  name        = "mmu-assignment-alb-sg"
  description = "Allow inbound HTTPS/HTTP from the internet"
  # vpc_id    = aws_vpc.main_vpc.id # Ensure your VPC resource is referenced here

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
  }
}

# Private App Tier SG
resource "aws_security_group" "app_sg" {
  name        = "mmu-assignment-app-sg"
  description = "Allow inbound strictly from ALB"
  # vpc_id    = aws_vpc.main_vpc.id

  ingress {
    description     = "Inbound from ALB only"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] 
  }

  egress {
    description = "Outbound to DB Tier on MySQL port 3306"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  }
}

# Highly Restricted DB Tier SG
resource "aws_security_group" "db_sg" {
  name        = "mmu-assignment-db-sg"
  description = "Allow inbound strictly from App Tier"
  # vpc_id    = aws_vpc.main_vpc.id

  ingress {
    description     = "Inbound from App Tier only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["127.0.0.1/32"] 
  }
}

# =========================================================================
# 4. HTTPS CONFIGURATION (Self-Signed TLS/SSL for Load Balancer)
# =========================================================================
resource "tls_private_key" "app_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "app_cert" {
  private_key_pem = tls_private_key.app_key.private_key_pem

  subject {
    common_name  = "mmu-secure-migration.local"
    organization = "MMU Cloud Security Group"
  }

  validity_period_hours = 720 
  
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "imported_cert" {
  private_key      = tls_private_key.app_key.private_key_pem
  certificate_body = tls_self_signed_cert.app_cert.cert_pem
}
