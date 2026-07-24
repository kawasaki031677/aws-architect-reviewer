---
name: aws-reliability
description: AWS reliability review criteria covering Multi-AZ, Auto Scaling, backups, disaster recovery, and single points of failure.
---

# AWS Reliability Review Criteria

Review failure isolation, recovery objectives, redundancy, and tested recovery procedures.

## Multi-AZ and Scaling

- Production workloads should span at least two AZs; critical workloads may require three.
- **REL-MAZ-001** (CRITICAL): Production RDS is not Multi-AZ.
- **REL-MAZ-002** (CRITICAL): A database subnet group contains only one subnet or AZ.
- **REL-MAZ-003** (WARNING): Application subnets are concentrated in one AZ.
- **REL-MAZ-004** (WARNING): ECS services are not distributed across multiple AZs.
- **REL-MAZ-005** (WARNING): Traffic-serving EC2 instances are not in a multi-AZ ASG.
- **REL-ASG-001** (CRITICAL): A production workload runs without Auto Scaling or equivalent redundancy.
- **REL-ASG-002** (WARNING): ASG `min_size` is one for a critical service.
- **REL-ASG-003** (WARNING): `min_size == max_size` prevents recovery scaling.
- **REL-ASG-004** (WARNING): ECS services lack Application Auto Scaling.
- **REL-ASG-005** (WARNING): Scaling policies lack connected CloudWatch alarms.
- **REL-ASG-006** (INFO): Prefer target tracking when it fits the workload.

## Backups and DR

- **REL-BKP-001** (CRITICAL): RDS backup retention is zero or final snapshots are disabled.
- **REL-BKP-002** (CRITICAL): DynamoDB point-in-time recovery is disabled.
- **REL-BKP-003** (WARNING): EFS backups are not configured.
- **REL-BKP-004** (WARNING): EBS backups or AWS Backup policies are missing.
- **REL-BKP-005** (WARNING): A centralized backup plan and vault are missing.
- **REL-DR-001** (WARNING): S3 cross-region replication is missing for regional recovery needs.
- **REL-DR-002** (WARNING): Route 53 health checks and failover routing are missing.
- **REL-DR-003** (WARNING): DNS failover is not tested.
- **REL-DR-004** (INFO): RTO and RPO are not documented.
- **REL-DR-005** (INFO): Recovery procedures are not tested regularly.

## Single Points of Failure

- **REL-SPOF-001** (CRITICAL): A single EC2, NAT gateway, database subnet, or cache node serves production traffic.
- **REL-SPOF-002** (CRITICAL): A single network path or AZ can stop the service.
- **REL-SPOF-003** (CRITICAL): An external dependency has no retry, timeout, or fallback strategy.
- **REL-SPOF-004** (WARNING): A Lambda, API Gateway, SQS, or SNS workflow lacks a DLQ or retry policy.