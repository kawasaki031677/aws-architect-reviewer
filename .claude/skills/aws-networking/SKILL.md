---
name: aws-networking
description: AWSネットワーク設計の知識ベース。VPCアーキテクチャ・サブネット分離・ルートテーブル設計・Transit Gateway・Direct Connect・ハイブリッド接続パターンを対象とする。AWS Well-ArchitectedネットワークおよびVPCベストプラクティスに準拠。
---

# AWSネットワーク設計レビュー基準

準拠基準:
- AWS Well-Architectedパフォーマンス効率柱（ネットワークセクション）
- AWS VPCベストプラクティス
- AWSネットワークアーキテクチャパターン
- AWS Direct Connect設計パターン

---

## VPC設計

### CIDR計画
- VPC間でCIDRを重複させない（将来のピアリングやTGW接続を妨げる）
- 大規模環境は `/16`、マイクロサービス単位のVPCは `/20`〜`/22`
- 将来の拡張のためにIPアドレス空間を確保する

### ルール
- **NET-VPC-001**（CRITICAL）: 本番ワークロードにデフォルトVPCを使用しない
- **NET-VPC-002**（WARNING）: 全本番VPCでVPC Flow Logsを有効にすること
- **NET-VPC-003**（WARNING）: `enable_dns_support = true` と `enable_dns_hostnames = true` を明示的に設定すること
- **NET-VPC-004**（WARNING）: VPCのCIDRがオンプレミスや他のVPCのCIDRと重複しないこと
- **NET-VPC-005**（INFO）: S3とDynamoBoxへのゲートウェイVPCエンドポイントを追加する（無料、セキュリティ向上）
- **NET-VPC-006**（INFO）: SSM・ECR・Secrets ManagerへのインターフェースVPCエンドポイントでトラフィックをプライベート化する

### パターン例
```hcl
# 良い例: 適切に設定されたVPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "prod-vpc" }
}

resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
}
```

---

## サブネット分離（パブリック / プライベート / 隔離）

### 3層サブネットパターン（本番環境では必須）
```
インターネット
      │
[パブリックサブネット]  ← ALB・NATゲートウェイ・踏み台ホスト
      │
[プライベートサブネット] ← EC2・ECS・Lambda・EKSノード
      │
[隔離サブネット]       ← RDS・ElastiCache・OpenSearch
```

### ルール
- **NET-SUB-001**（CRITICAL）: アプリケーションサーバーをパブリックサブネットに配置しない
- **NET-SUB-002**（CRITICAL）: データベースインスタンスは隔離サブネット（インターネットルートなし）に配置すること
- **NET-SUB-003**（WARNING）: 踏み台ホストはAWS Systems Manager Session Managerに置き換えることを推奨
- **NET-SUB-004**（WARNING）: セキュリティグループに加えてNACLで多層防御を実装すること
- **NET-SUB-005**（WARNING）: 各ティア（パブリック/プライベート/隔離）は2AZ以上にまたがること
- **NET-SUB-006**（INFO）: サブネットにティアタグを付与する（`Tier = public | private | isolated`）

### IaCでのサブネット種別の識別方法
```hcl
# パブリックサブネットの指標: IGWへのデフォルトルートがある
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id  # ← パブリック
}

# プライベートサブネットの指標: NATゲートウェイ経由のルートがある
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id  # ← プライベート
}

# 隔離サブネット: インターネットへのデフォルトルートが一切ない
```

---

## ルートテーブル設計

### ルール
- **NET-RT-001**（CRITICAL）: プライベートサブネットのルートテーブルにIGWをデフォルトルートとして設定しない
- **NET-RT-002**（WARNING）: 全サブネットに明示的なルートテーブル関連付けを設定する（デフォルトルートテーブルを使わない）
- **NET-RT-003**（WARNING）: ピアリングルートには広いアグリゲートではなく特定のCIDRを使用する
- **NET-RT-004**（INFO）: 隔離サブネットにはローカルVPCルートとVPCエンドポイントルートのみ設定する
- **NET-RT-005**（INFO）: ティアごとにルートテーブルを分離する（共有ルートテーブルを使わない）

---

## Transit Gateway

### TGWを使うべきケース
- 3つ以上のVPCが通信する場合 → メッシュピアリングよりTGWがシンプル
- 集中セキュリティ検査のハブスポークトポロジー
- AWS RAMを使ったマルチアカウント接続

### ルール
- **NET-TGW-001**（WARNING）: 3つ以上のVPCにピアリング接続がある場合はTransit Gatewayを検討する
- **NET-TGW-002**（WARNING）: TGWルートテーブルによるセグメンテーションがない場合、全VPCがフルメッシュ通信できる
- **NET-TGW-003**（WARNING）: TGWにFlow LogsまたはCloudWatchモニタリングを設定すること
- **NET-TGW-004**（INFO）: AWS Resource Access Manager（RAM）を使ってマルチアカウントでTGWを共有する
- **NET-TGW-005**（INFO）: TGWルートテーブルを使って本番/非本番/共有サービスVPCをセグメント化する

### パターン例
```hcl
# 良い例: ルートテーブルによるTGWのセグメンテーション
resource "aws_ec2_transit_gateway_route_table" "prod" {}
resource "aws_ec2_transit_gateway_route_table" "nonprod" {}

# 異なるルートテーブルにより開発→本番のトラフィックを防止
```

---

## Direct Connect・ハイブリッド接続

### 接続オプション（帯域幅・コスト昇順）
1. **Site-to-Site VPN** — 最大1.25Gbps、暗号化、インターネット経由
2. **Direct Connect** — 1〜100Gbps、専用線、低レイテンシ
3. **Direct Connect + VPN** — 最もセキュア（プライベート + 暗号化）

### ルール
- **NET-DX-001**（WARNING）: VPNトンネルの冗長性がない（AWSは2つのトンネルを作成するが両方を監視すること）
- **NET-DX-002**（WARNING）: Direct Connectの冗長接続がない（単一DX = 単一障害点）
- **NET-DX-003**（WARNING）: VPNトンネル状態変化のCloudWatchアラームを設定すること
- **NET-DX-004**（INFO）: 高帯域幅（1Gbps超の持続的利用）の場合、VPNよりDirect Connectのほうがコスト効率が良い
- **NET-DX-005**（INFO）: Direct Connect Gatewayを使って複数のVPC/リージョンに接続する
- **NET-DX-006**（INFO）: VPCピアリングよりAWS PrivateLinkでサービス間接続を検討する

### VPN監視パターン例
```hcl
resource "aws_cloudwatch_metric_alarm" "vpn_tunnel_down" {
  alarm_name          = "vpn-トンネル状態"
  metric_name         = "TunnelState"
  namespace           = "AWS/VPN"
  statistic           = "Minimum"
  period              = 60
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
}
```

---

## PrivateLink

- **NET-PL-001**（INFO）: VPC間のサービス公開にはVPCピアリングではなくPrivateLink（NLB + エンドポイントサービス）を使用する
- **NET-PL-002**（INFO）: SaaSサービスへの接続にはVPN/インターネット経由ではなくPrivateLinkを使用する
- PrivateLinkはVPCルートテーブルの変更が不要で、ピアリングよりスケーラブル
