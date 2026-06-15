# AWSパフォーマンス効率（Performance Efficiency）チェック基準

AWS Well-Architectedフレームワーク「パフォーマンス効率」の柱に基づくIaCレビュー基準。

---

## コンピュートの選択

### EC2インスタンスタイプ
- ワークロード特性に合ったインスタンスファミリーを選択する
  - 汎用: `t3` / `t4g`（バースト）, `m6i` / `m7g`（安定）
  - コンピューティング最適化: `c6i` / `c7g`（CPU集約）
  - メモリ最適化: `r6i` / `r7g`（大容量RAM）
  - ストレージ最適化: `i3en` / `im4gn`（高IOPSストレージ）
- `t2.*` は旧世代。`t3.*` または `t4g.*` へ移行推奨
- ARM/Gravitonインスタンス（`t4g`, `m7g`, `c7g`, `r7g`）は同等パフォーマンスで約20%安価

### Lambda
- メモリ設定（`memory_size`）が128MBデフォルトのままは要確認（CPUもメモリ比例）
- タイムアウト（`timeout`）が3秒デフォルトのままで長時間処理をしていないか確認
- Lambda Power Tuningによるメモリ最適化を推奨（Recommendations）
- ARM/Graviton2アーキテクチャ（`architectures = ["arm64"]`）でコスト・パフォーマンス向上

### ECS/Fargate
- Fargateタスク定義のCPU/メモリ設定が実際のワークロードと乖離していないか確認
- 可変ワークロードはFargate Spotの併用を推奨

---

## キャッシュの活用

### ElastiCache
- セッション管理・高頻度読み取りにElastiCache（Redis/Memcached）を使用する
- ElastiCacheなしでRDSへの読み取り集中ワークロードを送っていないか確認
- Redisはクラスターモードで高可用性を確保する

### DynamoDB Accelerator（DAX）
- DynamoDBへの読み取り集中ワークロードにDAXを検討する
- レイテンシがマイクロ秒レベルの要件がある場合は必須

### CloudFront
- 静的アセット（HTML/CSS/JS/画像）はCloudFront経由で配信する
- API GatewayにCloudFrontを前置して地理的に分散する
- キャッシュポリシーを明示的に設定する（デフォルトTTLのままにしない）

### API Gateway
- APIレスポンスキャッシュを有効化する（`cache_cluster_enabled = true`）
- キャッシュサイズとTTLをエンドポイント特性に合わせて設定する

---

## データベース最適化

### RDS 読み取りレプリカ
- 読み取り集中ワークロードでRDSリードレプリカを設定する
- `aws_db_instance` に `read_replica_identifier` または `replicate_source_db` を使用
- Aurora の場合は `aws_rds_cluster_instance` を複数定義する

### RDS Proxy
- Lambda→RDS接続はRDS Proxyを必ず経由する（コネクションプーリング）
- 高同時接続ワークロードでRDS Proxyを検討する

### データベースエンジン
- MySQL 5.7 / PostgreSQL 11 以下は旧バージョン → アップグレード推奨
- Aurora はMySQL/PostgreSQLの最大5倍のスループット（移行推奨）
- DynamoDB のキー設計が偏っていないか（ホットパーティション問題）を確認

---

## ストレージの最適化

### EBS ボリュームタイプ
- `gp2` は旧世代。`gp3` へ移行すると同等性能でコスト削減
- IOPSが安定して高い場合は `io2` Block Express を検討
- スループット重視は `st1`（HDD）、コスト重視のコールドデータは `sc1`

### S3
- 頻繁にアクセスしないデータはS3-IA または S3 Glacier に移行する（ライフサイクルポリシー）
- S3 Intelligent-Tiering でアクセスパターンに応じた自動階層化を検討

---

## ネットワークパフォーマンス

### 配置グループ（Placement Group）
- HPC・低レイテンシワークロードには `cluster` 配置グループを使用する
- 同一AZ内での密集配置でネットワーク帯域幅を最大化する

### Enhanced Networking
- 高帯域幅ワークロードはENA（Elastic Network Adapter）対応インスタンスを使用する
- EFAはHPC/機械学習ワークロード向け

---

## Auto Scaling

### スケーリングポリシー
- ターゲット追跡ポリシー（Target Tracking）でCPU使用率・リクエスト数を基準にスケール
- ステップスケーリングよりターゲット追跡が推奨（自動調整）
- スケールインのクールダウン期間を適切に設定する（デフォルト300秒）
- 予測スケーリング（Predictive Scaling）で事前スケールアウトを検討

---

## 重大度基準

| 重大度 | 条件例 |
|--------|--------|
| CRITICAL | RDS Proxyなしで高同時Lambda→RDS接続・旧世代インスタンス（t2, m4, c4）の本番利用 |
| WARNING | CloudFrontなし静的配信・キャッシュ未設定・gp2ボリューム・Lambda 128MBデフォルト |
| INFO | Graviton未使用・リードレプリカ未設定・DAX未検討 |
