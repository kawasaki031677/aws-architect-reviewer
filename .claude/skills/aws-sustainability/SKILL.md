---
name: aws-sustainability
description: AWS sustainability review criteria for Graviton, Spot capacity, scheduling, lifecycle policies, and efficient architectures.
---

# Sustainability Review Criteria

Reduce energy and resource consumption by matching capacity to demand and using efficient managed services.

- **SUS-GRAV-001** (CRITICAL): Compatible EC2 workloads use x86 without evaluating Graviton.
- **SUS-GRAV-002** (CRITICAL): Compatible RDS workloads use x86 without evaluating Graviton.
- **SUS-SCHED-001** (WARNING): Non-production EC2 resources run continuously without a schedule.
- **SUS-SCHED-002** (WARNING): Non-production RDS resources run continuously without a schedule.
- **SUS-S3-001** (WARNING): S3 lifecycle rules do not transition or expire data.
- **SUS-S3-002** (WARNING): S3 Intelligent-Tiering is not considered for uncertain access patterns.
- **SUS-NET-001** (WARNING): S3 traffic uses NAT instead of a gateway endpoint.
- **SUS-LAMBDA-001** (INFO): New Lambda functions do not use `architectures = ["arm64"]` when compatible.
- **SUS-SRVLESS-001** (INFO): Intermittent workloads run on always-on EC2 instead of serverless services.
- **SUS-TAG-001** (INFO): Environment tags are missing for carbon and cost attribution.
- **SUS-STOR-001** (INFO): EBS snapshot lifecycle management is missing.

Consider Fargate Spot for interruptible tasks, Auto Scaling for demand-based capacity, and AWS Instance Scheduler or EventBridge for non-production shutdowns.
