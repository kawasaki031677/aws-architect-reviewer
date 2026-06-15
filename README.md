# AWS Well-Architectedレビューエージェント

**Claude Codeで構築したAIによるAWSインフラ自動審査ツール**

TerraformおよびCloudFormationのコードを[AWS Well-Architectedフレームワーク](https://aws.amazon.com/jp/architecture/well-architected/)の6つの柱で自動分析し、優先度付きの実践的なMarkdownレポートを生成します。

---

## できること

Claude Codeでコマンドを1つ実行するだけ：

```
/review
```

エージェントが以下を行います：

1. **スキャン** — リポジトリ内のTerraform（`.tf`）とCloudFormation（`.yaml`/`.json`）ファイルを検出
2. **委譲** — Well-Architectedの各柱を担当する専門サブエージェントに並行してレビューを依頼
3. **外部参照** — MCPを通じてAWSドキュメント・料金情報をリアルタイムで参照
4. **レポート出力** — 全問題を Critical / Warning / 推奨事項で分類したMarkdownレポートを生成

---

## アーキテクチャ

```
ユーザー: /review
              │
              ▼
┌─────────────────────────┐
│      orchestrator       │  リポジトリスキャン・作業ルーティング・結果集約
└────────────┬────────────┘
             │ 並行して起動（7エージェント）
    ┌────┬───┴──┬────┬────────┬────────────┬─────────────┐
    ▼    ▼      ▼    ▼        ▼            ▼             ▼
┌──────┐┌────┐┌─────┐┌──────┐┌──────────┐┌───────────┐┌──────────────┐
│secur-││cost││reli-││netwo-││operation-││performance││sustainabil-  │
│ity   ││    ││abil-││rking ││al-excel- ││reviewer   ││ity-reviewer  │
│revie-││revw││ity  ││revw  ││lence-revw││           ││              │
└──┬───┘└─┬──┘└──┬──┘└──┬───┘└────┬─────┘└─────┬─────┘└──────┬───────┘
   └───────┴──────┴──────┴─────────┴────────────┴─────────────┘
                                   │
                                   ▼
                        ┌──────────────────┐
                        │  report-writer   │  Markdownレポート生成
                        └──────────────────┘
                                   │
                                   ▼
                  well-architected-review-YYYYMMDD.md
```

---

## チェック対象

このエージェントは **AWS Well-Architectedフレームワーク6つの柱** に加え、AWSインフラで問題が多発する **ネットワーク設計** を独自観点として追加した計7観点でレビューします。

### AWS Well-Architectedフレームワーク（6柱）

| 観点 | チェック項目 |
|---|---|
| セキュリティ | IAM最小権限・KMS暗号化・S3パブリックアクセス・セキュリティグループ・CloudTrail・Secrets Manager |
| コスト最適化 | NATゲートウェイ台数・RDS適正サイズ・EC2/ECSプロビジョニング・S3ライフサイクル・CloudFrontキャッシュ |
| 信頼性 | Multi-AZ設計・Auto Scaling・バックアップ&DR・単一障害点 |
| 運用上の優秀性 | CloudWatch監視・ログ保持期間・X-Rayトレーシング・タグ戦略・SSM Session Manager・AWS Config |
| パフォーマンス効率 | インスタンス世代・Graviton推奨・ElastiCacheキャッシュ・RDS Proxy・EBSボリュームタイプ・Lambda最適化 |
| 持続可能性 | Graviton/ARM移行・Fargate Spot・EC2スポット・非本番スケジューリング・S3ライフサイクル効率化 |

### 独自追加観点

| 観点 | チェック項目 | 追加理由 |
|---|---|---|
| ネットワーク設計 | VPC設計・サブネット分離・ルートテーブル・Transit Gateway・Direct Connect・PrivateLink | ネットワーク起因の問題（パブリック露出・サブネット誤配置・ルーティング欠落）はセキュリティ・信頼性・パフォーマンスの複数柱にまたがるため、横断的に専任エージェントでレビューする |

---

## 必要環境

| 項目 | 必須 | 説明 |
|---|:---:|---|
| [Claude Code](https://claude.ai/code) | ✅ | CLIまたはIDEプラグイン |
| `uv` / `uvx` | ✅ | MCPサーバー（aws-docs・aws-pricing）の起動に必要 |
| AWS認証情報 | △ | `aws-pricing` MCPを使ったリアルタイム料金取得に必要。未設定でもドキュメント参照によるレビューは実行可能 |

---

## クイックスタート

### 1. リポジトリをクローン

```bash
git clone https://github.com/kawasaki031677/aws-architect-reviewer
cd aws-architect-reviewer
```

### 2. Claude Codeで開く

```bash
claude .
```

### 3. レビューを実行

```
/review
```

特定ディレクトリのみレビューする場合：

```
/review examples/terraform
```

### 4. レポートを確認

レポートはプロジェクトルートに `well-architected-review-YYYYMMDD.md` として出力されます。

---

## 出力サンプル

```markdown
# AWS Well-Architectedレビューレポート

審査日: 2026年06月14日
IaCの種類: terraform
解析ファイル数: 3件

## エグゼクティブサマリー

| 観点           | Critical | Warning | 推奨事項 |
|----------------|----------|---------|---------|
| セキュリティ       | 5        | 3       | 2       |
| コスト最適化       | 0        | 4       | 3       |
| 信頼性             | 3        | 2       | 1       |
| ネットワーク設計   | 2        | 3       | 2       |
| 運用上の優秀性     | 1        | 5       | 2       |
| パフォーマンス効率 | 0        | 3       | 4       |
| 持続可能性         | 0        | 2       | 5       |
| **合計**           | **11**   | **22**  | **19**  |

総合リスクレベル: 🔴 高

## Criticalな問題

### [SEC-IAM-001] IAMポリシーにワイルドカードアクション

- **重大度:** CRITICAL
- **リソース:** `aws_iam_policy.app`
- **ファイル:** `main.tf`
- **問題の詳細:** IAMポリシーが `Action: "*"` を `Resource: "*"` に付与 — フル管理者権限と同等
- **修正方法:** アプリケーションが必要とする操作のみに制限してください
  （例: `s3:GetObject`, `dynamodb:Query`）。
  CloudTrailのログからIAM Access Analyzerを使って最小権限ポリシーを生成することもできます。
```

---

## ディレクトリ構成

```
.claude/
├── agents/
│   ├── orchestrator.md                       # レビュー調整役
│   ├── security-reviewer.md                  # セキュリティ柱担当
│   ├── cost-reviewer.md                      # コスト最適化担当
│   ├── reliability-reviewer.md               # 信頼性担当
│   ├── networking-reviewer.md                # ネットワーク設計担当
│   ├── operational-excellence-reviewer.md    # 運用上の優秀性担当
│   ├── performance-reviewer.md               # パフォーマンス効率担当
│   ├── sustainability-reviewer.md            # 持続可能性担当
│   └── report-writer.md                      # レポート生成担当
│
├── skills/
│   ├── well-architected/                     # フレームワーク概要・重大度定義
│   ├── aws-security/                         # CIS Benchmark・Security Hub準拠ルール
│   ├── aws-cost/                             # コスト最適化パターン・料金データ
│   ├── aws-reliability/                      # 信頼性パターン・DR戦略
│   ├── aws-networking/                       # VPC・TGW・DX設計パターン
│   ├── aws-operational-excellence/           # 監視・ログ・タグ・CI/CDパターン
│   ├── aws-performance/                      # インスタンス選択・キャッシュ・DB最適化
│   └── aws-sustainability/                   # Graviton・Spot・ライフサイクル効率化
│
├── commands/
│   └── review.md                             # /reviewコマンド定義
│
└── settings.json                             # エージェント権限設定

.mcp.json                                     # MCPサーバー設定（2サーバー）

examples/
├── terraform/                                # 問題を含むTerraformサンプル（動作確認用）
└── cloudformation/                           # 問題を含むCloudFormationサンプル（動作確認用）
```

---

## MCPサーバー

エージェントは2つのMCPサーバーを活用して外部知識を参照します：

| MCPサーバー | 用途 | 利用エージェント |
|---|---|---|
| `awslabs.aws-documentation-mcp-server` | 最新のAWSサービスドキュメントとベストプラクティスを参照 | 全レビュアー |
| `awslabs.aws-pricing-mcp-server` | コスト影響試算のためのリアルタイムAWS料金を取得 | cost / performance / sustainability |

### セットアップ

```bash
# uvのインストール（AWSのMCPサーバー用）
curl -LsSf https://astral.sh/uv/install.sh | sh
```

`.mcp.json` はリポジトリに含まれており、Claude Codeが自動的に両サーバーを起動します。追加設定は不要です。

> **Note:** `aws-pricing` によるリアルタイム料金取得にはAWS認証情報が必要です。
> ```bash
> aws sso login   # SSO利用時
> # または
> aws configure   # アクセスキー利用時
> ```
> 未認証の場合でも、AWSドキュメントを参照したレビューは正常に動作します。

---

## エージェントの拡張方法

### 新しい観点のレビュアーを追加する

1. `.claude/agents/my-reviewer.md` を作成する
2. `.claude/skills/my-pillar/SKILL.md` にスキルを追加する
3. `orchestrator.md` を更新して新しいエージェントを起動するよう設定する

### 新しいチェックルールを追加する

`.claude/skills/` 配下の該当スキルファイルを編集してください。各ルールは以下の形式に従います：

```
**[観点-カテゴリ-NNN]**（重大度）: ルールの説明
```

---

## コントリビュート

プルリクエスト歓迎です！

1. リポジトリをフォーク
2. 該当するスキルファイルにルールIDと重大度を付けてルールを追加
3. `examples/terraform/` または `examples/cloudformation/` にテストケースを追加
4. PRを作成 — エージェントが自分自身のコードをレビューします

---

## 関連リソース

- [AWS Well-Architectedフレームワーク（日本語）](https://docs.aws.amazon.com/ja_jp/wellarchitected/latest/framework/welcome.html)
- [AWS Security Hub FSBP](https://docs.aws.amazon.com/ja_jp/securityhub/latest/userguide/fsbp-standard.html)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [Claude Codeドキュメント](https://docs.anthropic.com/ja/docs/claude-code)
- [Model Context Protocol](https://modelcontextprotocol.io)

---

*[Claude Code](https://claude.ai/code) で構築 · [Anthropic Claude](https://anthropic.com) 搭載*
