---
name: aws-cost
description: AWS cost optimization guidance for NAT gateways, RDS sizing, EC2/ECS cost patterns, S3 lifecycle policies, and CloudFront caching.
---

# AWS Cost Optimization Review Criteria

Apply the AWS Well-Architected Cost Optimization pillar and current pricing data when available.

## Rules

- **COST-NAT-001** (WARNING): Do not deploy NAT gateways in every AZ for non-production without a documented need.
- **COST-NAT-002** (WARNING): Add free S3 and DynamoDB gateway endpoints where applicable.
- **COST-NAT-003** (INFO): Consider interface endpoints for frequently used AWS services.
- **COST-NAT-004** (INFO): Review traffic patterns when NAT data-processing charges become material.
- **COST-RDS-001** (WARNING): Disable Multi-AZ in non-production only when availability requirements allow it.
- **COST-RDS-002** (WARNING): Use Performance Insights and workload metrics to right-size RDS instances.
- **COST-RDS-003** (WARNING): Keep development and staging backup retention within the required window.
- **COST-RDS-004** (INFO): Consider Aurora Serverless v2 for variable or low-traffic workloads.
- **COST-RDS-005** (INFO): Consider Reserved Instances for predictable production databases.
- **COST-RDS-006** (INFO): Use storage autoscaling instead of large up-front allocations.
- **COST-EC2-001** (WARNING): Document the reason for very large EC2 instance types.
- **COST-EC2-002** (WARNING): Without Auto Scaling, low-load periods cannot scale down automatically.
- **COST-EC2-003** (INFO): Use Spot Instances for interruption-tolerant workloads.
- **COST-EC2-004** (INFO): Add Team, Project, Environment, and CostCenter tags.
- **COST-ECS-001** (WARNING): Document unusually large ECS task CPU or memory settings.
- **COST-ECS-002** (WARNING): Consider Spot capacity providers for non-critical tasks.
- **COST-ECS-003** (INFO): Consider Fargate Spot for batch workloads.
- **COST-ECS-004** (INFO): Right-size Fargate CPU and memory settings.
- **COST-S3-001** (WARNING): Buckets without lifecycle rules can accumulate data without limit.
- **COST-S3-002** (WARNING): Versioned buckets need expiration rules for noncurrent versions.
- **COST-S3-003** (INFO): Transition older objects to S3 Standard-IA when appropriate.
- **COST-S3-004** (INFO): Transition archive data to Glacier after the required retention period.
- **COST-S3-005** (INFO): Expire temporary and log objects according to retention requirements.
- **COST-S3-006** (INFO): Use S3 Intelligent-Tiering for unpredictable access patterns.
- **COST-CF-001** (WARNING): Consider CloudFront for frequently accessed S3 content.
- **COST-CF-002** (WARNING): Configure cache policies and compression to reduce origin traffic.
- **COST-CF-003** (INFO): Review CloudFront cache hit ratio and origin request metrics.
- **COST-CF-004** (INFO): Consider Origin Shield for high-volume or multi-region origins.
- **COST-CF-005** (INFO): Select a price class that matches audience geography.
- **COST-TAG-001** (WARNING): Missing cost allocation tags prevent reliable cost attribution.

Use Terraform `default_tags` and AWS Config rules to enforce tagging. Prefer explicit environment-aware counts and lifecycle policies over permanently provisioned capacity.