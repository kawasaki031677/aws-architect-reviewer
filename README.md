# AWS Well-Architected Review Agent

**An AI-powered AWS infrastructure review tool built for Claude Code.**

This project analyzes Terraform and CloudFormation against the six AWS Well-Architected pillars and an additional networking perspective. It produces a prioritized Markdown report with practical remediation guidance.

## What It Does

Run one command in Claude Code:

```text
/review
```

The agents scan IaC files, delegate parallel reviews to specialist agents, consult AWS documentation and pricing through MCP when available, and write findings as Critical, Warning, or Recommendation.

## Review Perspectives

| Perspective | Focus |
| --- | --- |
| Security | IAM least privilege, KMS, S3 access, security groups, CloudTrail, and Secrets Manager |
| Cost Optimization | NAT gateways, RDS sizing, EC2/ECS capacity, S3 lifecycle, and CloudFront |
| Reliability | Multi-AZ, Auto Scaling, backups, disaster recovery, and single points of failure |
| Operational Excellence | CloudWatch, log retention, X-Ray, tagging, Systems Manager, and AWS Config |
| Performance Efficiency | Instance generations, Graviton, caches, RDS Proxy, EBS, and Lambda sizing |
| Sustainability | Graviton/ARM, Fargate Spot, EC2 Spot, schedules, and storage lifecycle |
| Networking | VPCs, subnet isolation, route tables, Transit Gateway, Direct Connect, and PrivateLink |

## Architecture

```text
/review
   |
   v
orchestrator -- scans IaC and delegates the file list
   |
   +--> security-reviewer
   +--> cost-reviewer
   +--> reliability-reviewer
   +--> networking-reviewer
   +--> operational-excellence-reviewer
   +--> performance-reviewer
   +--> sustainability-reviewer
   |
   v
report-writer -- writes well-architected-review-YYYYMMDD.md
```

## Requirements

| Requirement | Required | Notes |
| --- | :---: | --- |
| [Claude Code](https://claude.ai/code) | Yes | CLI or IDE plugin |
| `uv` / `uvx` | Yes | Starts the AWS documentation and pricing MCP servers |
| AWS credentials | Optional | Required only for real-time pricing queries |

## Quick Start

```bash
git clone https://github.com/kawasaki031677/aws-architect-reviewer
cd aws-architect-reviewer
claude .
```

Run the full review or target one directory:

```text
/review
/review examples/terraform
```

The report is written to the repository root as `well-architected-review-YYYYMMDD.md`.

## Repository Layout

```text
.claude/
├── agents/          # Specialist reviewers and orchestration
├── skills/          # Well-Architected and pillar-specific criteria
└── commands/        # /review command
.mcp.json            # MCP server configuration
examples/            # Intentionally flawed Terraform and CloudFormation samples
```

## MCP Servers

- `awslabs.aws-documentation-mcp-server` provides current AWS documentation and best practices.
- `awslabs.aws-pricing-mcp-server` provides real-time AWS pricing for cost estimates.

Install `uv` when needed:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Documentation review still works without AWS credentials. Pricing queries require an authenticated AWS session.

## Adding Rules

1. Add a reviewer rule to the relevant file under `.claude/skills/`.
2. Use the rule format `[PILLAR]-[CATEGORY]-[three-digit sequence]`.
3. Add a Terraform or CloudFormation test case under `examples/`.
4. Run `/review` and inspect the generated report.

## Contributing

Pull requests are welcome. Please keep documentation in English, preserve the JSON output contract, and include a focused sample or validation step for new rules.

## Related Resources

- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Security Hub FSBP](https://docs.aws.amazon.com/securityhub/latest/userguide/fsbp-standard.html)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Model Context Protocol](https://modelcontextprotocol.io)
