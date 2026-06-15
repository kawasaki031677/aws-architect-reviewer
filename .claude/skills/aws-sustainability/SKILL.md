# AWS持続可能性（Sustainability）チェック基準

AWS Well-Architectedフレームワーク「持続可能性」の柱に基づくIaCレビュー基準（2021年追加）。
リソース効率の最大化・不要なリソース削減・カーボンフットプリント低減を目的とする。

---

## Graviton（ARM）プロセッサの活用

### 対象インスタンスファミリー
x86インスタンスから同等のGravitonインスタンスへ移行することで電力効率を最大60%向上：

| x86 | Graviton 代替 | 改善効果 |
|-----|--------------|---------|
| t3.* | t4g.* | ~20%コスト削減・省電力 |
| m6i.* | m7g.* | ~20%コスト削減・省電力 |
| c6i.* | c7g.* | ~20%コスト削減・省電力 |
| r6i.* | r7g.* | ~20%コスト削減・省電力 |

### RDS on Graviton
- `r7g.*` / `m7g.*` インスタンスでMySQL・PostgreSQL・Aurora を実行
- x86世代より電力効率が高く、コストも安価

### Lambda on ARM
- `architectures = ["arm64"]` でGravitonで実行（x86比 約20%コスト削減）

---

## サーバーレス・マネージドサービスの活用

### Lambda vs 常時起動EC2
- 断続的なワークロードにEC2の常時起動を使用していないか確認
- 適切なユースケースではLambda/Fargateへの移行を推奨（アイドル時ゼロコスト）

### Fargate vs EC2
- コンテナワークロードはFargate（マネージド）を優先
- Fargateはプロビジョニング不要でリソース効率が高い

### Aurora Serverless
- 間欠的なデータベースワークロードはAurora Serverless v2を検討
- 使用時のみ課金されるため、非本番環境での常時起動RDSより効率的

---

## スポットインスタンス・Fargate Spot

### EC2 Spot
- フォールトトレラントなワークロード（バッチ処理・CI/CD）にEC2 Spotを使用
- Auto Scaling Group に `on_demand_base_capacity` + `spot_allocation_strategy` を設定
- Mixed Instances Policyで複数インスタンスタイプを指定してスポット可用性を確保

### Fargate Spot
- ECSサービスのキャパシティプロバイダーにFargate Spotを追加
- 本番サービスは `base=1` でオンデマンドを確保しつつSpot混在を推奨

---

## 過剰プロビジョニングの排除

### Auto Scaling による需要追従
- 手動固定キャパシティではなくAuto Scalingで需要に追従する
- ASGの `min_size` と `max_size` の乖離が小さすぎる場合（スケールの余地なし）は要確認

### EC2 Instance Scheduler
- 非本番環境（開発・検証）のEC2/RDSを業務時間外に自動停止する
- AWS Instance Scheduler（CloudFormation）またはLambda+EventBridgeで実装

### Lambda 同時実行数
- 未使用のLambda関数に不必要な同時実行予約（`reserved_concurrent_executions`）を設定していないか確認

---

## データ転送量の最小化

### CloudFront
- 静的アセットをCloudFront経由で配信（オリジンへの転送量削減）
- 地域に近いエッジから配信してデータ転送距離を短縮

### VPCエンドポイント
- S3/DynamoDBへのゲートウェイエンドポイントを設定（NAT経由のデータ転送削減）
- インターネット経由のデータ転送を最小化

### S3 Transfer Acceleration
- ユーザーが地理的に分散している場合はTransfer AccelerationよりCloudFrontを優先

---

## ストレージの効率化

### S3ライフサイクル
- アクセス頻度に応じてストレージクラスを移行する（S3-IA→Glacier）
- S3 Intelligent-Tieringで自動的に最適なクラスに移行
- 不要なデータを自動削除するライフサイクルルール（`expiration`）を設定

### EBSスナップショット
- 古いスナップショットを自動削除するDLM（Data Lifecycle Manager）を設定
- 不要なスナップショットの蓄積を防ぐ

---

## 重大度基準

| 重大度 | 条件例 |
|--------|--------|
| CRITICAL | 本番環境でInstance Schedulerなしの非本番リソースが24/7稼働（大規模な場合） |
| WARNING | Graviton未使用（x86インスタンス）・Fargateなし常時起動EC2・ライフサイクル未設定 |
| INFO | Lambda arm64未設定・Aurora Serverless未検討・Spot未使用 |
