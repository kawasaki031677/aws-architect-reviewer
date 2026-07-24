---
name: well-architected
description: Overall AWS Well-Architected review policy covering the six pillars, severity definitions, and IaC resource coverage.
---

# AWS Well-Architected Review Framework

Review every IaC resource through the six pillars: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, and Sustainability. Networking is an additional cross-pillar perspective in this project.

## Severity

| Severity | Meaning |
| --- | --- |
| **CRITICAL** | Immediate security, availability, compliance, or data-loss risk; fix before production. |
| **WARNING** | Material deviation from best practice; address in the near term. |
| **INFO** | Improvement that increases maturity or efficiency. |

## Review Method

1. Identify Terraform and CloudFormation resources and their relationships.
2. Apply the relevant specialist skill rules.
3. Report each finding with a stable rule ID, resource, file, severity, detail, and remediation.
4. Avoid speculative findings and distinguish missing configuration from intentional configuration.
5. Return machine-readable JSON to the orchestrator.

Review VPC, EC2/ASG, RDS/Aurora, S3, IAM, Lambda, ECS/EKS, CloudFront, Route 53, KMS, NAT, and Transit Gateway resources when present.
