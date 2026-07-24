---
name: aws-security
description: AWS security review criteria for IAM, KMS, S3, security groups, CloudTrail, and Secrets Manager, aligned with Security Hub and CIS guidance.
---

# AWS Security Review Criteria

Apply least privilege, defense in depth, encryption, auditability, and secure secret handling.

## IAM

- **SEC-IAM-001** (CRITICAL): IAM policies use `Action: "*"`.
- **SEC-IAM-002** (CRITICAL): IAM policies use `Resource: "*"` without justification.
- **SEC-IAM-003** (WARNING): Permission boundaries are missing for delegated roles.
- **SEC-IAM-004** (WARNING): Trust policies lack restrictive conditions.
- **SEC-IAM-005** (INFO): Prefer IAM roles and IAM Identity Center over long-lived access keys.
- **SEC-IAM-006** (CRITICAL): Human users lack MFA.
- **SEC-IAM-007** (WARNING): Root account access keys or uncontrolled root usage are present.
- **SEC-IAM-008** (WARNING): Password policy does not meet the organization’s length and rotation requirements.
- **SEC-IAM-009** (INFO): Use IAM Identity Center instead of unmanaged individual IAM users.

## Encryption and S3

- **SEC-KMS-001** (CRITICAL): RDS storage encryption is disabled.
- **SEC-KMS-002** (CRITICAL): S3 default encryption is missing.
- **SEC-KMS-003** (WARNING): Customer-managed KMS key use is not justified or controlled.
- **SEC-KMS-004** (WARNING): EBS volumes are not encrypted by default.
- **SEC-KMS-005** (WARNING): DynamoDB server-side encryption is missing.
- **SEC-KMS-006** (INFO): Enable automatic KMS key rotation.
- **SEC-KMS-007** (CRITICAL): S3 does not enforce HTTPS-only access.
- **SEC-KMS-008** (WARNING): ALB or ELB listeners do not require TLS 1.2 or later.
- **SEC-KMS-009** (WARNING): RDS does not enforce SSL connections where required.
- **SEC-S3-001** through **SEC-S3-004** (CRITICAL): S3 public access block settings are missing or disabled.
- **SEC-S3-005** (WARNING): Versioning is missing for important data.
- **SEC-S3-006** (WARNING): S3 server access logging is missing.
- **SEC-S3-007** (WARNING): Object Lock is missing where immutability is required.
- **SEC-S3-008** (INFO): Consider Intelligent-Tiering or cross-region replication when appropriate.

## Security Groups and Audit

- **SEC-SG-001** (CRITICAL): SSH is open to `0.0.0.0/0` or `::/0`.
- **SEC-SG-002** (CRITICAL): RDP is open to `0.0.0.0/0` or `::/0`.
- **SEC-SG-003** (CRITICAL): Database ports are open to the public internet.
- **SEC-SG-004** (WARNING): Public resources allow more than HTTP/HTTPS ingress.
- **SEC-SG-005** (WARNING): Security group rules lack descriptions.
- **SEC-SG-006** (INFO): Restrict egress to required destinations where practical.
- **SEC-SG-007** (INFO): Use VPC endpoints to reduce unnecessary internet egress.
- **SEC-CT-001** (CRITICAL): A multi-region CloudTrail is missing.
- **SEC-CT-002** (CRITICAL): CloudTrail log file validation is disabled.
- **SEC-CT-003** (WARNING): CloudTrail is not integrated with CloudWatch Logs.

## Secrets

- **SEC-SM-001** (CRITICAL): Credentials or API keys are hardcoded in IaC or user data.
- **SEC-SM-002** (CRITICAL): Secrets are exposed through parameters, logs, or stack events.
- **SEC-SM-003** (WARNING): Secrets Manager or SSM Parameter Store is not used for runtime secrets.
- **SEC-SM-004** (WARNING): Secret rotation is not configured.
