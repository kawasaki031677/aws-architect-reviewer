# Sample Terraform - intentionally contains Well-Architected issues for demonstration.
# Running /review should detect these issues.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─── VPC ───────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  # NET-VPC-003 WARNING: enable_dns_support and enable_dns_hostnames are not set
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  # NET-SUB-005 WARNING: only one Availability Zone is defined
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
}

# NET-VPC-002 WARNING: VPC Flow Logs are not defined

# ─── NAT Gateway ────────────────────────────────────────────────────────────────

resource "aws_eip" "nat" {}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  # COST-NAT-001 WARNING: no environment-aware count setting (same setup in all environments)
}

# ─── Security Group ─────────────────────────────────────────────────────────────

resource "aws_security_group" "web" {
  name   = "web-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SEC-SG-001 CRITICAL: SSH is exposed to the entire internet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ─── EC2 ────────────────────────────────────────────────────────────────────────

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id # NET-SUB-001 CRITICAL: application server is in a public subnet

  # REL-SPOF-001 CRITICAL: single EC2 instance without an ASG
  # SEC-SM-001 CRITICAL: credentials are hardcoded below

  # SEC-SM-001 CRITICAL: credentials must not be hardcoded in user_data
  # Correct approach: retrieve them dynamically from aws_secretsmanager_secret or aws_ssm_parameter

  tags = {
    Name = "app-server"
    # COST-TAG-001 WARNING: Environment, Team, and Project tags are missing
  }
}

# ─── RDS ────────────────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = [aws_subnet.private.id]
  # REL-MAZ-001: only one subnet (single AZ)
}

resource "aws_db_instance" "main" {
  identifier        = "prod-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "appdb"
  username = "admin"
  # SEC-SM-001 CRITICAL: password must not be hardcoded; manage it with aws_secretsmanager_secret

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.web.id]

  multi_az                = false # REL-MAZ-001 CRITICAL: Multi-AZ is disabled
  storage_encrypted       = false # SEC-KMS-001 CRITICAL: encryption is disabled
  backup_retention_period = 0     # REL-BKP-001 CRITICAL: backups are disabled
  skip_final_snapshot     = true
}

# ─── S3 ────────────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "data" {
  bucket = "${var.project_name}-data"
  # SEC-S3-001/002/003/004 CRITICAL: public access block is not configured
  # COST-S3-001 WARNING: lifecycle policy is not configured
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
  # COST-S3-002 WARNING: versioning is enabled but no lifecycle rule exists for old versions
}

# ─── IAM ───────────────────────────────────────────────────────────────────────

resource "aws_iam_role" "app" {
  name = "app-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "app" {
  name = "app-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"   # SEC-IAM-001 CRITICAL: wildcard action
      Resource = "*"   # SEC-IAM-002 CRITICAL: wildcard resource
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.app.arn
}
