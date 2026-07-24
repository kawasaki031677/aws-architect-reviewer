# AWS Well-Architected Review Agent - CLAUDE.md

This file contains project settings automatically referenced by Claude Code at session start.

## Project Overview

This Claude Code agent system automatically reviews Terraform and CloudFormation IaC across the six AWS Well-Architected pillars plus the additional networking perspective, for seven perspectives in total.

## Structure

```
.claude/
├── agents/          # Specialized reviewer subagents
├── skills/          # Shared knowledge bases and check rules
└── commands/        # /review command definition
.mcp.json            # MCP server configuration (aws-docs / aws-pricing)
examples/            # Sample IaC for validation
```

### Agents

| Agent | Responsibility |
|---|---|
| `orchestrator` | IaC scanning, delegation, and aggregation |
| `security-reviewer` | Security pillar |
| `cost-reviewer` | Cost optimization pillar |
| `reliability-reviewer` | Reliability pillar |
| `operational-excellence-reviewer` | Operational excellence pillar |
| `performance-reviewer` | Performance efficiency pillar |
| `sustainability-reviewer` | Sustainability pillar |
| `networking-reviewer` | Additional cross-pillar networking review |
| `report-writer` | Markdown report generation |

### Skills

| Skill | Used by |
|---|---|
| `well-architected` | orchestrator (overall review policy) |
| `aws-security` | security-reviewer |
| `aws-cost` | cost-reviewer |
| `aws-reliability` | reliability-reviewer |
| `aws-operational-excellence` | operational-excellence-reviewer |
| `aws-performance` | performance-reviewer |
| `aws-sustainability` | sustainability-reviewer |
| `aws-networking` | networking-reviewer |

## Development Conventions

### Documentation Language
- **Write all documentation in English**, including code comments, skills, agent definitions, and the README.

### Rule ID Naming

Rule IDs in each skill must use this format:

```
[pillar prefix]-[category]-[three-digit sequence]
```

| Pillar | Prefix |
|---|---|
| Security | SEC |
| Cost | COST |
| Reliability | REL |
| Networking | NET |
| Operational Excellence | OPS |
| Performance | PERF |
| Sustainability | SUS |

Examples: `SEC-IAM-001`, `COST-NAT-003`, `REL-MAZ-001`

### Agent Output Format

Reviewer agents must always return JSON:

```json
{
  "pillar": "security",
  "critical": [
    {
      "rule": "SEC-IAM-001",
      "resource": "aws_iam_policy.app",
      "file": "main.tf",
      "severity": "CRITICAL",
      "detail": "Detailed description of the finding",
      "remediation": "Remediation guidance, including documentation URLs where possible"
    }
  ],
  "warnings": [],
  "recommendations": []
}
```

### Agent `tools:` Field

To call MCP tools, a subagent must list them explicitly in its `tools:` front matter. Always include the corresponding MCP tool name when adding or changing a tool.

MCP tool name format: `mcp__<server-name>__<tool-name>`

Example: `mcp__aws-docs__search_documentation`

### MCP Servers

| Server | Package | Purpose |
|---|---|---|
| `aws-docs` | `awslabs.aws-documentation-mcp-server` | AWS documentation search and reference |
| `aws-pricing` | `awslabs.aws-pricing-mcp-server` | Real-time pricing and cost estimates |

Starting the MCP servers requires `uvx`. The agents still work when it is unavailable, but reviews run without MCP references.

## Using `/review`

```
/review                    # Review the current directory
/review examples/terraform # Review a specific directory
```

The report is written to `well-architected-review-YYYYMMDD.md` (ignored by Git).

## Notes

- Generated `well-architected-review-*.md` reports are excluded from Git.
- `.claude/settings.local.json` is excluded from Git.
- Sample IaC in `examples/` **intentionally contains issues** for validation.
