---
name: aws-networking
description: AWS networking review criteria covering VPCs, subnet isolation, route tables, Transit Gateway, Direct Connect, and hybrid connectivity.
---

# AWS Networking Review Criteria

Review VPC architecture, subnet isolation, routing, resilience, and private connectivity.

## VPC and Subnets

- Plan non-overlapping CIDR ranges with future VPC and Transit Gateway growth in mind.
- Enable `enable_dns_support` and `enable_dns_hostnames` when private DNS is required.
- **NET-VPC-001** (CRITICAL): Do not use the default VPC for production workloads.
- **NET-VPC-002** (WARNING): VPC Flow Logs are missing in a production VPC.
- **NET-VPC-003** (WARNING): VPC DNS support or hostnames are disabled or implicit.
- **NET-VPC-004** (WARNING): VPC CIDR ranges overlap with on-premises or other VPC ranges.
- **NET-VPC-005** (INFO): Add S3 and DynamoDB gateway endpoints.
- **NET-VPC-006** (INFO): Add interface endpoints for SSM, ECR, and Secrets Manager where private access is required.
- **NET-SUB-001** (CRITICAL): Application servers are placed in a public subnet.
- **NET-SUB-002** (CRITICAL): Database instances are not in isolated subnets with no internet route.
- **NET-SUB-003** (WARNING): Bastion hosts are used where Session Manager would be safer.
- **NET-SUB-004** (WARNING): Network ACL defense in depth is missing where required.
- **NET-SUB-005** (WARNING): Public, private, or isolated tiers are not distributed across at least two AZs.
- **NET-SUB-006** (INFO): Subnets lack clear tier tags such as `public`, `private`, or `isolated`.

## Routing

- **NET-RT-001** (CRITICAL): A private route table sends traffic directly to an Internet Gateway.
- **NET-RT-002** (WARNING): Subnets lack explicit route table associations.
- **NET-RT-003** (WARNING): Peering routes use overly broad aggregate CIDRs.
- **NET-RT-004** (INFO): Isolated route tables contain more than local and endpoint routes.
- **NET-RT-005** (INFO): Route tables are shared across workload tiers.

## Transit Gateway and Direct Connect

- **NET-TGW-001** (WARNING): Multiple VPCs lack a documented Transit Gateway strategy.
- **NET-TGW-002** (WARNING): TGW route tables do not isolate environments.
- **NET-TGW-003** (WARNING): Transit Gateway Flow Logs are missing.
- **NET-TGW-004** (INFO): TGW sharing through AWS RAM is not documented.
- **NET-TGW-005** (INFO): TGW attachments lack clear environment and ownership tags.
- **NET-DX-001** (WARNING): A single VPN or Direct Connect path creates a connectivity SPOF.
- **NET-DX-002** (WARNING): Direct Connect lacks a redundant connection or backup VPN.
- **NET-DX-003** (WARNING): VPN tunnel health is not monitored.
- **NET-DX-004** (INFO): Use Direct Connect for sustained high-volume traffic.
- **NET-DX-005** (INFO): Consider Direct Connect Gateway for multi-region or multi-VPC connectivity.
- **NET-DX-006** (INFO): Consider PrivateLink for service-to-service private access.