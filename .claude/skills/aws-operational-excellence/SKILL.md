---
name: aws-operational-excellence
description: AWS operational excellence review criteria for monitoring, logging, tracing, tagging, Systems Manager, CI/CD, and AWS Config.
---

# Operational Excellence Review Criteria

Review whether teams can observe, operate, change, and recover workloads consistently.

- **OPS-MON-001** (CRITICAL): EC2 lacks CPU and status-check alarms.
- **OPS-MON-002** (CRITICAL): RDS lacks CPU, connection, and storage alarms.
- **OPS-MON-003** (WARNING): Performance Insights is not enabled where needed.
- **OPS-LOG-001** (CRITICAL): CloudWatch log groups and retention policies are missing.
- **OPS-LOG-002** (CRITICAL): VPC Flow Logs are missing.
- **OPS-LOG-003** (WARNING): RDS error, slow-query, or general log exports are missing.
- **OPS-LOG-004** (INFO): S3 server access logging is not configured.
- **OPS-TRC-001** (WARNING): Distributed tracing is missing for multi-service applications.
- **OPS-TAG-001** (WARNING): Resources lack Environment, Project, Owner, or Team tags.
- **OPS-TAG-002** (WARNING): Terraform provider `default_tags` are not configured.
- **OPS-SSH-001** (CRITICAL): SSH is exposed instead of using Systems Manager Session Manager.
- **OPS-CFG-001** (CRITICAL): AWS Config rules for encryption, public access, or Multi-AZ are missing.
- **OPS-DASH-001** (WARNING): A dashboard for key service metrics is missing.
- **OPS-SNS-001** (INFO): Alarm notification topics and subscriptions are missing.
- **OPS-PARAM-001** (INFO): Runtime configuration is not externalized to SSM or Secrets Manager.
- **OPS-RUNBOOK-001** (INFO): SSM Automation runbooks for common incidents are missing.

Prefer short feedback loops, automated deployments, immutable changes, documented runbooks, and tested rollback procedures.
