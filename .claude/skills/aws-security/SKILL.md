---
name: aws-security
description: AWSセキュリティ観点の知識ベース。IAM最小権限・暗号化・S3パブリックアクセス・セキュリティグループ強化・CloudTrail・Secrets Managerを対象とする。AWS Well-Architectedセキュリティ柱・Security Hub・CIS AWS Benchmarkに準拠。
---

# AWSセキュリティレビュー基準

準拠基準:
- AWS Well-Architectedセキュリティ柱（WAF-SEC）
- AWS Security Hub 基本セキュリティベストプラクティス（FSBP）
- CIS AWS Foundations Benchmark v1.4

---

## IAM（Identity & Access Management）

### 最小権限の原則
- **SEC-IAM-001**（CRITICAL）: IAMポリシーに `Action: "*"` のワイルドカードを使用しない
- **SEC-IAM-002**（CRITICAL）: IAMポリシーに `Resource: "*"` のワイルドカードを明示的な理由なく使用しない
- **SEC-IAM-003**（WARNING）: IAMロールにはアクセス許可境界（Permission Boundary）を設定すること
- **SEC-IAM-004**（WARNING）: カスタムポリシーで付加価値がない場合のみAWSマネージドポリシーを使用する
- **SEC-IAM-005**（INFO）: サービスアカウントにはIAMユーザーよりIAMロールを推奨

### アイデンティティ基盤
- **SEC-IAM-006**（CRITICAL）: IAMユーザーにはMFAを必須とすること
- **SEC-IAM-007**（WARNING）: rootアカウントにアクセスキーを作成しないこと
- **SEC-IAM-008**（WARNING）: パスワードポリシーに複雑さ要件を設定する（最低14文字・定期ローテーション）
- **SEC-IAM-009**（INFO）: 個別IAMユーザーではなくAWS IAM Identity Center（旧SSO）を使用する

### CIS Benchmarkリファレンス
- CIS 1.1: rootアカウントの使用回避
- CIS 1.4: rootアカウントのアクセスキーが存在しないこと
- CIS 1.9: パスワードポリシーで最低14文字を要求すること
- CIS 1.16: IAMポリシーはグループまたはロールにのみ付与すること

---

## KMS暗号化

### 保存データの暗号化
- **SEC-KMS-001**（CRITICAL）: RDSインスタンスは `storage_encrypted = true` 必須
- **SEC-KMS-002**（CRITICAL）: S3バケットはデフォルト暗号化を設定すること（SSE-S3またはSSE-KMS）
- **SEC-KMS-003**（WARNING）: 機密データにはAWSマネージドキーではなくCMK（カスタマーマネージドキー）を使用する
- **SEC-KMS-004**（WARNING）: EBSボリュームは暗号化すること
- **SEC-KMS-005**（WARNING）: DynamoDBテーブルには `server_side_encryption` を有効にすること
- **SEC-KMS-006**（INFO）: CMKには自動キーローテーションを有効にすること（`enable_key_rotation = true`）

### 転送データの暗号化
- **SEC-KMS-007**（CRITICAL）: S3バケットポリシーでHTTPS専用アクセスを強制する
- **SEC-KMS-008**（WARNING）: ALB/ELBリスナーはTLS 1.2以上を使用すること
- **SEC-KMS-009**（WARNING）: RDSはSSL接続を強制すること

---

## S3セキュリティ

### パブリックアクセスブロック
- **SEC-S3-001**（CRITICAL）: `block_public_acls = true` 必須
- **SEC-S3-002**（CRITICAL）: `block_public_policy = true` 必須
- **SEC-S3-003**（CRITICAL）: `ignore_public_acls = true` 必須
- **SEC-S3-004**（CRITICAL）: `restrict_public_buckets = true` 必須

### 追加制御
- **SEC-S3-005**（WARNING）: 重要なデータにはS3バージョニングを有効にする
- **SEC-S3-006**（WARNING）: S3サーバーアクセスログを有効にする
- **SEC-S3-007**（WARNING）: コンプライアンスデータにはS3 Object Lockを使用する
- **SEC-S3-008**（INFO）: 耐障害性のためS3 Intelligent-TieringまたはクロスリージョンレプリケーションS3を有効にする

### CIS Benchmarkリファレンス
- CIS 2.1.1: S3バケットのパブリックアクセスをブロックすること
- CIS 2.1.2: S3バケットのバージョニングを有効にすること

---

## セキュリティグループ

### インバウンドルール
- **SEC-SG-001**（CRITICAL）: SSH（ポート22）への `0.0.0.0/0` または `::/0` からのインバウンドを禁止
- **SEC-SG-002**（CRITICAL）: RDP（ポート3389）への `0.0.0.0/0` または `::/0` からのインバウンドを禁止
- **SEC-SG-003**（CRITICAL）: DBポート（3306, 5432, 1433, 27017）への `0.0.0.0/0` からのインバウンドを禁止
- **SEC-SG-004**（WARNING）: パブリック向けリソースはHTTP（80）・HTTPS（443）のみ `0.0.0.0/0` を許可する
- **SEC-SG-005**（WARNING）: すべてのセキュリティグループルールに説明（description）を設定すること

### アウトバウンドルール
- **SEC-SG-006**（INFO）: 全アウトバウンドを許可するのではなく、必要なエグレスに制限する
- **SEC-SG-007**（INFO）: AWSサービス呼び出しにはVPCエンドポイントを使用してインターネットエグレスを削減する

---

## CloudTrail

- **SEC-CT-001**（CRITICAL）: 全リージョンでCloudTrailを有効にすること（`is_multi_region_trail = true`）
- **SEC-CT-002**（CRITICAL）: ログファイル検証を有効にすること（`enable_log_file_validation = true`）
- **SEC-CT-003**（WARNING）: CloudTrailログをCloudWatch Logsに送信すること
- **SEC-CT-004**（WARNING）: CloudTrailのS3バケットにアクセスログを有効にすること
- **SEC-CT-005**（WARNING）: CloudTrailのS3バケットをパブリックアクセス不可にすること
- **SEC-CT-006**（INFO）: 異常なAPIアクティビティの検出にCloudTrail Insightsを有効にする

### CIS Benchmarkリファレンス
- CIS 3.1: CloudTrailを全リージョンで有効にすること
- CIS 3.2: CloudTrailのログファイル検証を有効にすること
- CIS 3.4: CloudTrailをCloudWatch Logsに統合すること

---

## シークレット管理

- **SEC-SM-001**（CRITICAL）: IaCに認証情報（パスワード・APIキー・トークン）をハードコードしない
- **SEC-SM-002**（CRITICAL）: 環境変数にプレーンテキストのシークレットを設定しない
- **SEC-SM-003**（WARNING）: シークレットの管理にはSSM Parameter StoreよりAWS Secrets Managerを推奨
- **SEC-SM-004**（WARNING）: Secrets Managerのシークレットには自動ローテーションを設定する
- **SEC-SM-005**（INFO）: 機密設定にはSSM Parameter StoreのSecureString（Stringではなく）を使用する

---

## Terraformのパターン例

```hcl
# 良い例: 暗号化されたRDS
resource "aws_db_instance" "main" {
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn
}

# 悪い例: 暗号化なし
resource "aws_db_instance" "main" {
  storage_encrypted = false  # SEC-KMS-001 CRITICAL
}

# 良い例: S3パブリックアクセスブロック
resource "aws_s3_bucket_public_access_block" "main" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

## CloudFormationのパターン例

```yaml
# 良い例: 暗号化されたRDS
DBInstance:
  Type: AWS::RDS::DBInstance
  Properties:
    StorageEncrypted: true
    KmsKeyId: !Ref RDSKMSKey

# 悪い例: 暗号化なし
DBInstance:
  Type: AWS::RDS::DBInstance
  Properties:
    StorageEncrypted: false  # SEC-KMS-001 CRITICAL
```
