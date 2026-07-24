Run an AWS Well-Architected review against the repository's IaC.

## Command Behavior

1. Start the `orchestrator` agent to scan Terraform and CloudFormation files.
2. The orchestrator delegates to specialist reviewers:
   - `security-reviewer` - IAM, KMS, S3, security groups, CloudTrail, and Secrets Manager
   - `cost-reviewer` - NAT gateways, RDS, EC2/ECS sizing, S3 lifecycle, and CloudFront
   - `reliability-reviewer` - Multi-AZ, Auto Scaling, backups, DR, and single points of failure
   - `networking-reviewer` - VPC design, subnet isolation, routing, Transit Gateway, and Direct Connect
   - `operational-excellence-reviewer` - CloudWatch monitoring, log retention, X-Ray, and tagging
   - `performance-reviewer` - instance generations, caching, RDS Proxy, and Lambda optimization
   - `sustainability-reviewer` - Graviton, Spot usage, lifecycle policies, and non-production scheduling
3. The `report-writer` agent combines all results and generates a Markdown report.

## Usage

```
/review
```

To review a specific subdirectory:
```
/review examples/terraform
```

## Output

The command generates `well-architected-review-YYYYMMDD.md`.

Findings are classified as follows:
- 🔴 **CRITICAL** - Fix before production deployment.
- 🟡 **WARNING** - Address in the current sprint.
- 🟢 **INFO** - Add to the backlog.

## Start the Review

Start the review with the `orchestrator` agent. Pass the target directory specified by the user, or the current directory `.` when no target is specified.
