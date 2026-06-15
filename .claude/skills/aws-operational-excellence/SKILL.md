# AWS運用上の優秀性（Operational Excellence）チェック基準

AWS Well-Architectedフレームワーク「運用上の優秀性」の柱に基づくIaCレビュー基準。

---

## 監視・アラーム

### CloudWatch Alarms
- 全EC2インスタンスにCPU使用率アラームを設定する（閾値: 80%以上）
- RDSにCPU・接続数・空きストレージのアラームを設定する
- Lambda関数にエラー率・実行時間のアラームを設定する
- ALB/NLBに5xxエラー率・レイテンシアラームを設定する
- SQSキューにメッセージ滞留数（ApproximateNumberOfMessagesNotVisible）のアラームを設定する

### CloudWatch Dashboard
- 本番ワークロードのキーメトリクスを1つのダッシュボードに集約する
- ビジネスメトリクス（リクエスト数・エラー率・レイテンシ）を可視化する

---

## ログ管理

### CloudWatch Logs
- 全ロググループに保持期間を設定する（無期限は不可）
  - 本番: 90日以上
  - 非本番: 30日以上
- VPC Flow Logsを有効化してCloudWatch Logsへ送信する
- ALBアクセスログをS3に保存する
- API GatewayアクセスログをCloudWatch Logsへ送信する
- CloudTrailログをCloudWatch Logsと統合する

### ログの集約
- 複数サービスのログを単一のS3バケットまたはCloudWatch Logs Insightsで集約する
- ログにサービス名・環境名・リクエストIDを含める構造化ログを推奨

---

## 可観測性（Observability）

### X-Ray トレーシング
- Lambda関数でX-Rayトレーシングを有効化する（`tracing_config.mode = "Active"`）
- API Gatewayでトレーシングを有効化する（`xray_tracing_enabled = true`）
- ECSタスクでX-Ray サイドカーコンテナを設定する

### CloudWatch Insights
- Lambda Insights拡張機能を本番Lambdaに設定する
- Container Insightsをクラスター（ECS/EKS）で有効化する

---

## タグ戦略

### 必須タグ
以下のタグを全リソースに設定すること：
- `Environment`: `production` / `staging` / `development`
- `Project` or `Application`: プロジェクト・アプリ名
- `Owner` or `Team`: 担当チーム
- `CostCenter`: コストセンターコード

### タグ強制
- `aws_config_rule` または SCPでタグポリシーを強制する
- `default_tags` ブロック（Terraform）をプロバイダーレベルで設定する

---

## 安全な運用

### SSM Session Manager
- 本番EC2への直接SSHではなくSSM Session Manager を使用する
- SSHポート（22）のセキュリティグループルールが残っている場合は要警告
- Session Managerのセッションログ記録をS3/CloudWatch Logsに設定する

### Systems Manager（SSM）
- パッチ管理にAWS Systems Manager Patch Managerを使用する
- 設定管理にSSM State Managerを使用する
- 機密パラメーターはSSM Parameter Store（SecureString型）に保存する

---

## CI/CD パイプライン

### デプロイ自動化
- 手動デプロイを排除し、CodePipeline / GitHub Actions / GitLab CIで自動化する
- Blue/Greenデプロイ（CodeDeploy）またはローリングアップデートを設定する
- デプロイ前後の自動ヘルスチェックを組み込む

### IaC管理
- すべてのインフラ変更をIaC（Terraform/CloudFormation）経由で行う
- マニュアル変更（コンソール操作）を検知するAWS Configルールを設定する

---

## AWS Config

### コンプライアンスルール
- `required-tags` ルールで必須タグの存在を強制する
- `ec2-instance-no-public-ip` ルールで非意図的なパブリックIPを検知する
- `s3-bucket-public-read-prohibited` ルールでS3公開設定を監視する
- `rds-instance-public-access-check` でRDSパブリックアクセスを監視する
- Config Conformance PackでCIS AWS Foundationsベンチマークを適用する

---

## 重大度基準

| 重大度 | 条件例 |
|--------|--------|
| CRITICAL | 本番環境でCloudTrailが無効・全リソースにログ保持期間が未設定 |
| WARNING | CloudWatchアラームが未設定・X-Rayが無効・必須タグが欠落 |
| INFO | Dashboardが未設定・Container Insightsが未設定 |
