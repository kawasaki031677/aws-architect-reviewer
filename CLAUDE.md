# AWS Well-Architectedレビューエージェント — CLAUDE.md

このファイルはClaude Codeがセッション開始時に自動参照するプロジェクト設定です。

## プロジェクト概要

TerraformおよびCloudFormationのIaCコードに対して、AWS Well-Architectedフレームワーク（6柱）＋ネットワーク設計（独自追加）の計7観点で自動レビューを行うClaude Codeエージェントシステムです。

## 構成

```
.claude/
├── agents/          # サブエージェント（各観点の専門レビュアー）
├── skills/          # 共有知識ベース（チェックルール）
└── commands/        # /review コマンド定義
.mcp.json            # MCPサーバー設定（aws-docs / aws-pricing）
examples/            # 動作確認用サンプルIaC
```

### エージェント一覧

| エージェント | 役割 |
|---|---|
| `orchestrator` | IaCスキャン・委譲・集約 |
| `security-reviewer` | セキュリティ柱（Well-Architected） |
| `cost-reviewer` | コスト最適化柱（Well-Architected） |
| `reliability-reviewer` | 信頼性柱（Well-Architected） |
| `operational-excellence-reviewer` | 運用上の優秀性柱（Well-Architected） |
| `performance-reviewer` | パフォーマンス効率柱（Well-Architected） |
| `sustainability-reviewer` | 持続可能性柱（Well-Architected） |
| `networking-reviewer` | ネットワーク設計（独自追加：複数柱横断） |
| `report-writer` | Markdownレポート生成 |

### スキル一覧

| スキル | 参照元 |
|---|---|
| `well-architected` | orchestrator（レビュー方針の全体観） |
| `aws-security` | security-reviewer |
| `aws-cost` | cost-reviewer |
| `aws-reliability` | reliability-reviewer |
| `aws-operational-excellence` | operational-excellence-reviewer |
| `aws-performance` | performance-reviewer |
| `aws-sustainability` | sustainability-reviewer |
| `aws-networking` | networking-reviewer |

## 開発規約

### ドキュメント言語
- **すべてのドキュメントは日本語で記述する**（コードコメント・スキル・エージェント定義・README含む）

### ルールID命名規則

各スキルのルールIDは以下の形式に従うこと：

```
[観点プレフィックス]-[カテゴリ]-[連番3桁]
```

| 観点 | プレフィックス |
|---|---|
| Security | SEC |
| Cost | COST |
| Reliability | REL |
| Networking | NET |
| Operational Excellence | OPS |
| Performance | PERF |
| Sustainability | SUS |

例: `SEC-IAM-001`、`COST-NAT-003`、`REL-MAZ-001`

### エージェントの出力形式

レビュアーエージェントは必ずJSON形式で返すこと：

```json
{
  "pillar": "security",
  "critical": [
    {
      "rule": "SEC-IAM-001",
      "resource": "aws_iam_policy.app",
      "file": "main.tf",
      "severity": "CRITICAL",
      "detail": "問題の詳細説明",
      "remediation": "修正方法（可能であればドキュメントURLを含む）"
    }
  ],
  "warnings": [],
  "recommendations": []
}
```

### エージェントのtools:フィールド

サブエージェントがMCPツールを呼び出すには、`tools:` フロントマターに明示的に列挙する必要がある。追加・変更時は必ず対応するMCPツール名を記載すること。

MCP ツール名の形式: `mcp__<サーバー名>__<ツール名>`

例: `mcp__aws-docs__search_documentation`

### MCPサーバー

| サーバー名 | パッケージ | 用途 |
|---|---|---|
| `aws-docs` | `awslabs.aws-documentation-mcp-server` | AWSドキュメント検索・参照 |
| `aws-pricing` | `awslabs.aws-pricing-mcp-server` | リアルタイム料金取得・コスト試算 |

MCPサーバーの起動には `uvx` が必要。未インストールの場合でもエージェントは動作するが、MCP参照なしでレビューを実施する。

## /review コマンドの使い方

```
/review                    # カレントディレクトリをレビュー
/review examples/terraform # 特定ディレクトリをレビュー
```

レポートは `well-architected-review-YYYYMMDD.md` として出力される（.gitignore対象）。

## 注意事項

- `well-architected-review-*.md`（生成レポート）はGit管理外（.gitignore済み）
- `.claude/settings.local.json` はGit管理外
- サンプルIaC（`examples/`）には**意図的に問題を含めている**（動作確認用）
