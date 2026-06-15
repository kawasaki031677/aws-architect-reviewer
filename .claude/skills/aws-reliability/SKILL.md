---
name: aws-reliability
description: AWS信頼性の知識ベース。Multi-AZ設計・Auto Scaling・バックアップ・リカバリ・DR戦略・単一障害点の排除を対象とする。AWS Well-Architected信頼性柱に準拠。
---

# AWS信頼性レビュー基準

準拠基準:
- AWS Well-Architected信頼性柱（WAF-REL）
- AWSディザスタリカバリホワイトペーパー
- AWSバックアップベストプラクティス

---

## Multi-AZ設計

### 設計原則
- 目標: 単一AZの障害でユーザー影響が発生しないこと
- 本番環境は最低2AZ、重要なワークロードは3AZを推奨
- 各ティア（Web・アプリ・データ）が独立してMulti-AZであること

### ルール
- **REL-MAZ-001**（CRITICAL）: 本番RDSは `multi_az = true` 必須
- **REL-MAZ-002**（CRITICAL）: ElastiCache Redisはレプリケーショングループで2ノード以上必須
- **REL-MAZ-003**（CRITICAL）: ALBは2AZ以上のサブネットにまたがること
- **REL-MAZ-004**（WARNING）: ECSサービスは2AZ以上のサブネットにデプロイすること
- **REL-MAZ-005**（WARNING）: トラフィックを受けるEC2インスタンスは2AZ以上のASGに配置すること
- **REL-MAZ-006**（INFO）: OpenSearch/Elasticsearchは3AZにまたがる3ノード以上を推奨

### パターン例
```hcl
# 良い例: Multi-AZ RDS
resource "aws_db_instance" "main" {
  multi_az = true
}

# 良い例: 複数AZにまたがるALB
resource "aws_lb" "main" {
  subnets = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id,
    aws_subnet.public_az3.id,
  ]
}
```

---

## Auto Scaling

### ルール
- **REL-ASG-001**（CRITICAL）: 本番サービスにはAuto Scalingを必ず設定すること
- **REL-ASG-002**（WARNING）: 本番ASGの `min_size` は2以上（1台 = 単一障害点）
- **REL-ASG-003**（WARNING）: `min_size == max_size` では自動スケールできない — 異なる値を設定すること
- **REL-ASG-004**（WARNING）: Application Auto ScalingなしのECSサービスは負荷スパイクに対応できない
- **REL-ASG-005**（WARNING）: スケーリングポリシーに接続されたCloudWatchアラームがない
- **REL-ASG-006**（INFO）: ステップスケーリングより目標値追跡スケーリングポリシーを推奨（管理が簡単）
- **REL-ASG-007**（INFO）: ステートフルなインスタンスにはスケールイン保護を設定する

### パターン例
```hcl
# 良い例: スケール余地があるASG
resource "aws_autoscaling_group" "main" {
  min_size         = 2
  max_size         = 10
  desired_capacity = 2
}

# 悪い例: スケール余地なし
resource "aws_autoscaling_group" "main" {
  min_size         = 2  # REL-ASG-003 WARNING
  max_size         = 2
  desired_capacity = 2
}
```

---

## バックアップ設計

### RTO/RPO目標値（参考）
| ティア | RTO | RPO |
|---|---|---|
| ミッションクリティカル | 1時間未満 | 15分未満 |
| ビジネスクリティカル | 4時間未満 | 1時間未満 |
| 標準 | 24時間未満 | 4時間未満 |
| 開発 | ベストエフォート | ベストエフォート |

### ルール
- **REL-BKP-001**（CRITICAL）: 本番RDSの `backup_retention_period` は7以上（0=無効）
- **REL-BKP-002**（CRITICAL）: DynamoDBのポイントインタイムリカバリ（PITR）を有効にすること
- **REL-BKP-003**（WARNING）: EFSにバックアップポリシーを設定すること
- **REL-BKP-004**（WARNING）: EBSボリュームをAWS Backupまたはスナップショットライフサイクルでカバーすること
- **REL-BKP-005**（WARNING）: AWS Backupプランで全重要リソースをカバーすること
- **REL-BKP-006**（INFO）: 重要なデータベースのクロスリージョンバックアップコピーを有効にする

---

## ディザスタリカバリ（DR）

### DR戦略（コスト低〜高・回復力低〜高）
1. **バックアップ＆リストア** — RPO: 数時間、RTO: 数時間
2. **パイロットライト** — RPO: 数分、RTO: 約10分
3. **ウォームスタンバイ** — RPO: 数秒、RTO: 数分
4. **マルチサイトアクティブ/アクティブ** — RPO: ≒0、RTO: ≒0

### ルール
- **REL-DR-001**（WARNING）: 重要なS3バケットにはクロスリージョンレプリケーションを設定する
- **REL-DR-002**（WARNING）: 重要エンドポイントにRoute53ヘルスチェックを設定すること
- **REL-DR-003**（WARNING）: 重要なDNSエントリにRoute53フェイルオーバールーティングポリシーを推奨
- **REL-DR-004**（INFO）: RTO/RPO目標値を重要リソースのコメントまたはタグに文書化する
- **REL-DR-005**（INFO）: セカンダリリージョンへのRDSリードレプリカをパイロットライトとして検討する
- **REL-DR-006**（INFO）: DRテストをIaCにリンクされたRunbookとして文書化する

---

## 単一障害点（SPOF）

### ルール
- **REL-SPOF-001**（CRITICAL）: ASEなし・ECSなしの単一EC2インスタンスが本番トラフィックを受けている
- **REL-SPOF-002**（CRITICAL）: フォールバックなしの単一NATゲートウェイ（プライベートサブネットのインターネット接続障害）
- **REL-SPOF-003**（CRITICAL）: レプリカやスタンバイなしのデータベース
- **REL-SPOF-004**（WARNING）: すべてのリソースが単一AZに集中している
- **REL-SPOF-005**（WARNING）: Lambda関数に同時実行数制限が未設定（アカウント全体の上限を枯渇させるリスク）
- **REL-SPOF-006**（WARNING）: API Gatewayにスロットリング制限がない（無制限リクエストがバックエンドを圧倒するリスク）
- **REL-SPOF-007**（INFO）: 同期依存関係の疎結合化にSQS/SNSを検討する

### リソース別SPOFチェック表
| リソース | SPOF指標 | 対策 |
|---|---|---|
| EC2 | ASGなし、単一インスタンス | 2AZ以上のASGを追加 |
| RDS | `multi_az = false` | Multi-AZを有効化 |
| NATゲートウェイ | 単一ゲートウェイ | 本番は各AZに1つ |
| Redis | 単一ノード | クラスターモード/レプリケーションを有効化 |
| ALB | 単一AZサブネット | 2AZ以上のサブネットを追加 |
| Lambda | 予約済み同時実行なし | 予約済み同時実行 + DLQを設定 |
