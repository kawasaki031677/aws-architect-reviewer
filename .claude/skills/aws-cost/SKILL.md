---
name: aws-cost
description: AWSコスト最適化の知識ベース。NATゲートウェイの合理化・RDSの適正サイジング・EC2/ECSのコストパターン・S3ライフサイクルポリシー・CloudFrontキャッシュを対象とする。AWS Well-Architectedコスト最適化柱に準拠。
---

# AWSコスト最適化レビュー基準

準拠基準:
- AWS Well-Architectedコスト最適化柱（WAF-COST）
- AWSコスト最適化ベストプラクティス
- AWS料金計算パターン

---

## NATゲートウェイ

### コスト参考値
- NATゲートウェイ: 約$0.045/時間（約$32/月） + $0.045/GB（データ処理料）
- 1TB/月のデータ転送: 1NATゲートウェイあたり約$77/月
- S3/DynamoDB向けVPCゲートウェイエンドポイント: **無料**

### ルール
- **COST-NAT-001**（WARNING）: 非本番環境で全AZにNATゲートウェイを配置しない
- **COST-NAT-002**（WARNING）: S3とDynamoDBにはVPCゲートウェイエンドポイントを設定する（無料、NATコスト削減）
- **COST-NAT-003**（INFO）: 他のAWSサービスにもVPCインターフェースエンドポイントを検討してNATトラフィックを削減する
- **COST-NAT-004**（INFO）: NATゲートウェイのデータ転送コストが月1万円超の場合、トラフィックパターンを見直す

### 環境別パターン
```hcl
# 良い例: 本番は全AZ、開発は1つ
resource "aws_nat_gateway" "main" {
  count = var.environment == "production" ? length(var.azs) : 1
}
```

---

## RDS構成

### コスト参考値
- db.r5.2xlarge: 約$0.48/時間（約$350/月）
- Multi-AZではインスタンスコストが2倍
- 自動バックアップストレージ: DBサイズまで無料、超過分は$0.095/GB/月

### ルール
- **COST-RDS-001**（WARNING）: 非本番環境ではMulti-AZを無効にする
- **COST-RDS-002**（WARNING）: Performance Insightsで使用状況を確認してインスタンスタイプを適正化する
- **COST-RDS-003**（WARNING）: 開発・ステージングのバックアップ保持期間は7日以内にする
- **COST-RDS-004**（INFO）: 可変または低トラフィックのワークロードにはAurora Serverless v2を検討する
- **COST-RDS-005**（INFO）: 予測可能な本番データベースにはリザーブドインスタンスを検討する（最大60%削減）
- **COST-RDS-006**（INFO）: 大容量ストレージの事前プロビジョニングではなくストレージ自動スケーリングを有効にする

### 環境別パターン
```hcl
# 良い例: 環境に応じたRDSサイジング
resource "aws_db_instance" "main" {
  instance_class          = var.environment == "production" ? "db.r5.2xlarge" : "db.t3.micro"
  multi_az                = var.environment == "production"
  backup_retention_period = var.environment == "production" ? 30 : 3
}
```

---

## EC2 / ECSサイジング

### コスト参考値
- t3.micro: 約$0.0104/時間（約$7.5/月）
- m5.4xlarge: 約$0.768/時間（約$553/月）
- スポットインスタンス: オンデマンド比最大90%割引
- Compute Savings Plans: オンデマンド比最大66%割引

### EC2ルール
- **COST-EC2-001**（WARNING）: 4xlarge以上の大型インスタンスには使用理由を文書化する
- **COST-EC2-002**（WARNING）: Auto Scalingなしでは低負荷時の自動縮退ができない
- **COST-EC2-003**（INFO）: フォールトトレラントな柔軟なワークロードにはスポットインスタンスを使用する
- **COST-EC2-004**（INFO）: EC2インスタンスにコスト配分タグを付与する（Team, Project, Environment）

### ECSルール
- **COST-ECS-001**（WARNING）: ECSタスクのCPUが4096超またはメモリが8192超の場合は使用理由を文書化する
- **COST-ECS-002**（WARNING）: 非クリティカルタスクにSpotを使うキャパシティプロバイダー戦略が未設定
- **COST-ECS-003**（INFO）: バッチワークロードにはFargate Spotを検討する（最大70%削減）
- **COST-ECS-004**（INFO）: タスクサイズを適正化する（Fargateでは過剰なCPU/メモリはコスト増）

---

## S3ライフサイクルポリシー

### コスト参考値
- S3 Standard: $0.023/GB/月
- S3 Standard-IA: $0.0125/GB/月
- S3 Glacier Instant Retrieval: $0.004/GB/月
- S3 Glacier Deep Archive: $0.00099/GB/月

### ルール
- **COST-S3-001**（WARNING）: ライフサイクルルールのないS3バケットはデータが無制限に蓄積する
- **COST-S3-002**（WARNING）: バージョニング有効のS3バケットには古いバージョンの有効期限を設定すること
- **COST-S3-003**（INFO）: 90日超のオブジェクトをS3-IAに移行する
- **COST-S3-004**（INFO）: アーカイブデータを180日後にGlacierに移行する
- **COST-S3-005**（INFO）: 一時・ログバケットに有効期限ルールを設定する
- **COST-S3-006**（INFO）: アクセスパターンが不規則なデータにはS3 Intelligent-Tieringを使用する

### パターン例
```hcl
# 良い例: ライフサイクルポリシー
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "移行と有効期限"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 180
      storage_class = "GLACIER"
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
```

---

## CloudFrontとキャッシュ

### コスト参考値
- インターネット向けデータ転送（CloudFrontなし）: $0.09/GB
- CloudFrontデータ転送: $0.0085/GB（10TB/月超）
- キャッシュヒットはオリジンリクエストを削減しデータ転送コストも下げる

### ルール
- **COST-CF-001**（WARNING）: 静的アセットのS3バケットにCloudFrontが未設定
- **COST-CF-002**（WARNING）: CloudFrontにキャッシュポリシーが未設定（全リクエストがオリジンへ到達）
- **COST-CF-003**（INFO）: CloudFrontの圧縮機能を有効にして転送量を削減する
- **COST-CF-004**（INFO）: マルチリージョンのオリジン向けにCloudFront Origin Shieldを検討する
- **COST-CF-005**（INFO）: CloudFrontの料金クラスを確認する（`PriceClass_100`はUS/EUのみで最安）

---

## コストタグ戦略

コスト配分のために必須とすべきタグ:
- `Environment`: production | staging | development
- `Team`: 担当チーム名
- `Project`: プロジェクト・プロダクト名
- `CostCenter`: 請求コストセンターコード

- **COST-TAG-001**（WARNING）: 必須コスト配分タグのないリソースは費用帰属ができない
- **COST-TAG-002**（INFO）: AWS ConfigルールまたはTagポリシーでタグ付けを強制する
