# ExaDB-XS End-to-End (Active Data Guard)

Provision a complete Oracle ExaDB-XS Active Data Guard environment using
OCI Resource Manager.

This stack creates:

- Full VCN networking
- Exascale Storage Vault
- One primary ExaDB-XS RAC VM Cluster
- One or more standby ExaDB-XS RAC VM Clusters
- One primary DB Home and one DB Home per standby
- One Primary CDB
- One or more Standby CDBs in a Data Guard group
- Optional Active Data Guard (read-only standby databases)

> Single-region deployment (both clusters in same Availability Domain)

------------------------------------------------------------------------

## Architecture Overview

VCN ├── Public Subnet │ ├── ExaDB-XS Cluster A (Primary) │ └── ExaDB-XS
Standby Cluster(s) │ └── Backup Subnet (Private)

Shared Exascale Storage Vault

Primary DB (Cluster A) ---\> Standby DB(s) ASYNC, Maximum
Performance

------------------------------------------------------------------------

## What This Stack Creates

### Networking

- VCN
- Internet Gateway
- NAT Gateway
- Service Gateway
- Public Route Table
- Private Route Table
- Security List (22, 1521, 5500 open)
- Public Subnet (for clusters)
- Backup Subnet (private)
- `standby_database_count` controls how many standby databases are
    created. The default is 1.

### Database Infrastructure

- Exascale Storage Vault
- 1 primary ExaDB-XS VM Cluster plus `standby_database_count` standby
  VM Cluster(s) (2-node RAC each)
- 1 primary DB Home plus `standby_database_count` standby DB Home(s)
- 1 × Primary Database (CDB + PDB)
- `standby_database_count` × Standby Database(s)
- Data Guard group (ASYNC, Maximum Performance)

------------------------------------------------------------------------

## Prerequisites

### OCI Requirements

- Sufficient quota for:
  - 1 primary ExaDB-XS VM Cluster plus the configured number of
        standby ExaDB-XS VM Clusters
  - Exascale Storage Vault
- IAM permissions:
  - manage database-family
  - manage virtual-network-family
  - manage orm-stacks

------------------------------------------------------------------------

### Grid Infrastructure Image (Critical Requirement)

- By default, the stack dynamically discovers the Grid Infrastructure
Image OCID for ExaDB-XS in the selected Availability Domain using the OCI
Terraform data source `oci_database_gi_version_minor_versions`.

The lookup uses:

- `gi_version` (default: `23.0.0.0`)
- `availability_domain`
- `shape_family = "EXADB_XS"`
- `compartment_ocid`

If you need to force a specific image, set `grid_image_id` to a valid
ExaDB-XS Grid Infrastructure Patch OCID (resource type: dbpatch). If
`grid_image_id` is empty, Terraform dynamically discovers the image from
`gi_version`.

Example format:

ocid1.dbpatch.oc1.`<region>`{=html}.xxxxx

Important:

- This OCID is region- and Availability-Domain-specific.
- It is NOT created by this Terraform stack.
- It must already exist in OCI.
- It must be compatible with ExaDB-XS.
- Deployment will fail if it does not match the selected region and
Availability Domain.

To retrieve available Grid Infrastructure images:

Using OCI CLI:

oci db patch list\
--compartment-id `<compartment_ocid>`{=html}\
--patch-type GRID_INFRASTRUCTURE\
--region `<region>`{=html}

Or via Console:

Oracle Database → Exadata Infrastructure → Patches

------------------------------------------------------------------------

## Required Inputs

```text
  Variable              Description
  --------------------- -------------------------------------
  compartment_ocid      Target compartment
  availability_domain   AD for ExaDB-XS
  db_admin_password     SYS password (\>=12 chars, complex)
  ssh_public_key        SSH public key for cluster nodes
```

Optional Grid Infrastructure inputs:

```text
  Variable              Description
  --------------------- -------------------------------------
  gi_version            GI version used for dynamic image lookup (default: 23.0.0.0)
  grid_image_id         Optional Grid Infrastructure patch OCID override
```

------------------------------------------------------------------------

## Deployment Steps

1. Go to OCI → Developer Services → Resource Manager
2. Create Stack
3. Upload ZIP (main.tf + schema.yaml)
4. Provide required inputs
5. Click Plan
6. Click Apply

Estimated provisioning time: 2--4 hours.

------------------------------------------------------------------------

## Post-Deployment Validation

Check Database Role:

SELECT database_role FROM v\$database;

Primary should show: PRIMARY\
Standby should show: PHYSICAL STANDBY

Check Data Guard processes:

SELECT process, status FROM v\$managed_standby;

Expect: - RFS running - MRP running

------------------------------------------------------------------------

## Important Notes

- Single-region deployment (not cross-region DR).
- Security list allows inbound from 0.0.0.0/0 (not production hardened).
- Auto-backup is disabled.
- Protection mode is MAXIMUM_PERFORMANCE.
- Terraform does not manage runtime switchover/failover state.

------------------------------------------------------------------------

## Destroying the Environment

From Resource Manager:

1. Open the Stack
2. Click Destroy

This removes all networking, clusters, DB Homes, databases, and Data
Guard configuration.

Destruction is irreversible.

------------------------------------------------------------------------

## Summary

This stack provisions a complete ExaDB-XS Active Data Guard environment
in a single region, including networking and storage.

The stack discovers a valid, region- and Availability-Domain-matching Grid
Infrastructure image OCID automatically unless `grid_image_id` is supplied as
an override.
