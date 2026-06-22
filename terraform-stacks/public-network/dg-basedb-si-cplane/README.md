# Public Data Guard Base DB (Single Instance - Control Plane Configuration)

This stack provisions a standalone public-network Data Guard lab with one primary DB system and one standby DB system. The standby is created through the DB system Data Guard flow using `source = "DATAGUARD"`.

## Prerequisites

- Provide the compartment OCID, region, SSH key, and database admin password via `terraform.tfvars` or environment variables.
- Restrict `public_ingress_cidrs` for real environments. The default allows SSH and SQL*Net from `0.0.0.0/0` for lab convenience.

## What this stack does

1. Creates a standalone VCN, internet gateway, public route table, and public DB subnet.
2. Creates a network security group that allows outbound traffic and inbound SSH / SQL*Net from `public_ingress_cidrs`.
3. Provisions the primary DB system with a new database.
4. Provisions the standby DB system with `source = "DATAGUARD"` and `primary_db_system_id` pointing to the primary DB system.

Useful outputs include the VCN, subnet, NSG, primary DB system, and standby DB system OCIDs.
