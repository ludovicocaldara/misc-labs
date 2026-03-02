# Data Guard Base DB (Single Instance – Manual 23ai)

This stack provisions **two single-instance DB Systems** in the same availability domain. They are intended to be the manual building blocks for a Data Guard / DGPDB configuration—you wire up the protection mode, transport, and role transitions yourself after the infrastructure is ready.

## Prerequisites

- Deploy the [`terraform-stacks/landing-zone`](../landing-zone) stack first. The DB subnet defined here reuses that VCN, private route table (if exported), and the shared **`misc_labs_nsg`** network security group so you can reach the databases from the bastion endpoint.
- Provide the compartment OCID, region, and SSH key via `terraform.tfvars` or environment variables.
- Optionally override `landing_zone_state_path` if the landing-zone state file lives somewhere else.

## What this stack does

1. Looks up the landing-zone outputs to reuse the VCN, NAT gateway, and (optionally) the shared private route table.
2. Creates one private subnet specific to this lab (default `10.50.20.0/24`) and associates it to the landing-zone route table (or creates a simple NAT-backed one when absent).
3. Provisions **two DB Systems** (`members = 2` by default) with Oracle Database 23ai, single-node shapes, and your supplied SSH key so you can log in via the bastion.

After `terraform apply` completes, connect through the bastion host exported by the landing zone and perform the manual steps to configure Data Guard transport, broker, or DGPDB workflows.
