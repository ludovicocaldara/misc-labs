# Data Guard Base DB (Single Instance – Manual 26ai)

This stack provisions **two single-instance DB Systems** in the same availability domain on a standalone public network. They are intended to be the manual building blocks for a Data Guard / DGPDB configuration—you wire up the protection mode, transport, and role transitions yourself after the infrastructure is ready.

## Prerequisites

- Provide the compartment OCID, region, and SSH key via `terraform.tfvars` or environment variables.
- Set `public_ingress_cidrs` to your client/network CIDR for safer testing. The default is `0.0.0.0/0` so the stack is immediately reachable in disposable test environments.

## What this stack does

1. Creates a standalone VCN, internet gateway, public route table, and public DB subnet.
2. Allows public IP assignment on the DB subnet.
3. Creates a network security group that allows outbound traffic and inbound TCP access for SSH (`22`) and SQL*Net (`1521`) from `public_ingress_cidrs`.
4. Provisions **two DB Systems** (`members = 2` by default) with Oracle Database 26ai, single-node shapes, and your supplied SSH key.

After `terraform apply` completes, connect directly to the DB System public IPs and perform the manual steps to configure Data Guard transport, broker, or DGPDB workflows.
