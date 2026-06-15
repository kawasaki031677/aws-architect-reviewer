# サンプルTerraform — Well-Architectedの問題を意図的に含んでいます（デモ用）
# /review を実行するとエージェントがこれらの問題を検出します。

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
  # NET-VPC-003 WARNING: enable_dns_support と enable_dns_hostnames が未設定
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  # NET-SUB-005 WARNING: 1つのAZしか定義されていない
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
}

# NET-VPC-002 WARNING: VPC Flow Logsが未定義

# ─── NATゲートウェイ ────────────────────────────────────────────────────────────

resource "aws_eip" "nat" {}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  # COST-NAT-001 WARNING: 環境を考慮したcount設定がない（全環境で同一構成）
}

# ─── セキュリティグループ ────────────────────────────────────────────────────────

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
    cidr_blocks = ["0.0.0.0/0"] # SEC-SG-001 CRITICAL: SSHが全世界に公開されている
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ─── EC2 ───────────────────────────────────────────────────────────────────────

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id # NET-SUB-001 CRITICAL: アプリサーバーがパブリックサブネットにある

  # REL-SPOF-001 CRITICAL: ASGなしの単一EC2インスタンス
  # SEC-SM-001 CRITICAL: 以下に認証情報がハードコードされている

  # SEC-SM-001 CRITICAL: user_dataへの認証情報ハードコードは禁止
  # 正しい方法: aws_secretsmanager_secret または aws_ssm_parameter から動的に取得する

  tags = {
    Name = "app-server"
    # COST-TAG-001 WARNING: Environment・Team・Projectタグが欠如している
  }
}

# ─── RDS ───────────────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = [aws_subnet.private.id]
  # REL-MAZ-001: サブネットが1つのみ（単一AZ）
}

resource "aws_db_instance" "main" {
  identifier        = "prod-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "appdb"
  username = "admin"
  # SEC-SM-001 CRITICAL: passwordのハードコードは禁止 — aws_secretsmanager_secretで管理すること

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.web.id]

  multi_az                = false # REL-MAZ-001 CRITICAL: Multi-AZが無効
  storage_encrypted       = false # SEC-KMS-001 CRITICAL: 暗号化が無効
  backup_retention_period = 0     # REL-BKP-001 CRITICAL: バックアップが無効
  skip_final_snapshot     = true
}

# ─── S3 ────────────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "data" {
  bucket = "${var.project_name}-data"
  # SEC-S3-001/002/003/004 CRITICAL: パブリックアクセスブロックが未設定
  # COST-S3-001 WARNING: ライフサイクルポリシーが未設定
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
  # COST-S3-002 WARNING: バージョニングは有効だが古いバージョンのライフサイクルルールがない
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
      Action   = "*"   # SEC-IAM-001 CRITICAL: ワイルドカードアクション
      Resource = "*"   # SEC-IAM-002 CRITICAL: ワイルドカードリソース
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.app.arn
}
