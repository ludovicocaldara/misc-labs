# Data Guard Base DB (RAC – Manual 26ai)

This stack provisions **RAC DB Systems** (default: 2 nodes per DBSystem, configurable) in the same availability domain. It is intended for building of clustered Oracle RAC environments to be manually configured with Data Guard for testing purposes. Node count and number of DBSystems are both configurable, so you can deploy 2-node (or 1-node) RAC clusters, with optional standby pairs for Data Guard demonstrations.

## Prerequisites

- Deploy the [`terraform-stacks/landing-zone`](../landing-zone) stack first. This stack reuses the landing-zone VCN, private route table, and networking artifacts, including the **`misc_labs_nsg`** network security group.
- Supply compartment OCID, region, and SSH key, usually via `terraform.tfvars` or environment variables.
- You may provide override variables if consuming the landing-zone network resources from another pipeline or deployment.

## What this stack does

1. Integrates with the landing-zone stack for VCN, subnet, NAT, NSG, and bastion endpoint definitions.
2. Creates a **dedicated private subnet** and associates it with the desired route table.
3. Provisions one or more **RAC DB Systems** (default: 2), each with the configured `node_count` (default: 2, but 1 or more are supported).
4. ASM is always enabled for storage (`storage_management` is ASM).

## Usage tips

- To create a 2-node RAC system: use default `node_count=2`.
- You can increase `members` to deploy multiple RAC DBSystems (e.g., primary + 2 standby for Data Guard).
- The stack does **not** automatically configure Data Guard or any database-level features—these are left for manual configuration after infra build.
- For single-instance DB deployment, use the [dg-basedb-si-manual](../dg-basedb-si-manual) stack instead.

After `terraform apply` completes, connect via the bastion host and manually perform cluster/database operations as needed.

## Outputs

- `bastion_endpoint_cidr`: CIDR of the discovered Bastion endpoint subnet for use in security rules.