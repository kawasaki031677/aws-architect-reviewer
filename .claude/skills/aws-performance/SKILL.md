---
name: aws-performance
description: AWS performance efficiency review criteria for instance generations, caching, database connectivity, storage, and Lambda sizing.
---

# Performance Efficiency Review Criteria

Choose resources and architecture based on measured workload characteristics and scaling behavior.

- **PERF-COMP-001** (WARNING): An older instance generation is used where a current generation is compatible.
- **PERF-COMP-002** (WARNING): Graviton is not evaluated for compatible workloads.
- **PERF-DB-001** (WARNING): EC2 or Lambda connects directly to RDS without connection pooling or RDS Proxy.
- **PERF-DB-002** (WARNING): Database instance sizing does not match production workload requirements.
- **PERF-DB-003** (WARNING): RDS uses gp2 or leaves the storage type implicit.
- **PERF-DB-004** (INFO): Read replicas are missing for read-heavy workloads.
- **PERF-CACHE-001** (WARNING): ElastiCache is missing for high-volume repeated reads.
- **PERF-CACHE-002** (WARNING): CloudFront is missing for cacheable static content.
- **PERF-CACHE-003** (INFO): Cache policies, TTLs, and hit ratios are not reviewed.
- **PERF-SCALE-001** (WARNING): Auto Scaling is missing for variable EC2 load.
- **PERF-SCALE-002** (WARNING): ECS or Lambda scaling policies are missing.
- **PERF-MON-001** (INFO): Performance metrics and alarms are insufficient for bottleneck detection.

Evaluate at least two AZs for production services and use load testing before selecting fixed capacity.
