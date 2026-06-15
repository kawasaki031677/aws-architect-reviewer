リポジトリ内のIaCに対してAWS Well-Architectedレビューを実行する。

## このコマンドの動作

1. `orchestrator` エージェントを起動してTerraformおよびCloudFormationファイルをスキャンする
2. オーケストレーターが専門レビューエージェントに委譲する：
   - `security-reviewer` — IAM・KMS・S3・セキュリティグループ・CloudTrail・Secrets
   - `cost-reviewer` — NATゲートウェイ・RDS・EC2/ECSサイジング・S3ライフサイクル・CloudFront
   - `reliability-reviewer` — Multi-AZ・Auto Scaling・バックアップ・DR・単一障害点
   - `networking-reviewer` — VPC設計・サブネット分離・ルーティング・Transit Gateway・Direct Connect
   - `operational-excellence-reviewer` — CloudWatch監視・ログ保持期間・X-Rayトレーシング・タグ戦略
   - `performance-reviewer` — インスタンス世代・キャッシュ・RDS Proxy・Lambda最適化
   - `sustainability-reviewer` — Graviton推奨・スポット活用・ライフサイクル・非本番稼働削減
3. `report-writer` エージェントが全結果を統合してMarkdownレポートを生成する

## 使い方

```
/review
```

特定のサブディレクトリをレビューする場合：
```
/review examples/terraform
```

## 出力

コマンドは `well-architected-review-YYYYMMDD.md` を生成する。

検出結果は以下で分類される：
- 🔴 **CRITICAL** — 本番デプロイ前に必ず修正
- 🟡 **WARNING** — 現スプリント内に対応
- 🟢 **INFO** — バックログに追加

## レビュー開始

`orchestrator` エージェントを使ってレビューを開始する。ユーザーが指定したターゲットディレクトリ（未指定の場合はカレントディレクトリ `.`）を渡すこと。
