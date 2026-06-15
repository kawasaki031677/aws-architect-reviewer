variable "aws_region" {
  description = "リソースをデプロイするAWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "リソース命名に使用するプロジェクト名"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "デプロイ環境（production | staging | development）"
  type        = string
  default     = "production"
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "environmentはproduction・staging・developmentのいずれかを指定してください"
  }
}

variable "ami_id" {
  description = "EC2インスタンス用のAMI ID"
  type        = string
  default     = "ami-0d52744d6551d851e"
}
