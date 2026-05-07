# ExaDB-XS End-to-End (Active Data Guard)

Provision a complete Oracle ExaDB-XS Active Data Guard environment using
OCI Resource Manager.

This stack creates:

-   Full VCN networking
-   Two Exascale Storage Vaults, one in each selected Availability Domain
-   Two ExaDB-XS RAC VM Clusters across Availability Domains
-   Two DB Homes
-   One Primary CDB
-   One Standby CDB (via Data Guard)
-   Optional Active Data Guard (read-only standby)

> Single-region, cross-Availability-Domain deployment.

------------------------------------------------------------------------

## Architecture Overview

VCN ├── Regional Public Subnet │ ├── AD1: ExaDB-XS Cluster A (Primary) │ └── AD2: ExaDB-XS
Cluster B (Standby) │ └── Regional Backup Subnet (Private)

Primary Exascale Storage Vault (AD1) + Standby Exascale Storage Vault (AD2)

Primary DB (Cluster A) ---\> Standby DB (Cluster B) ASYNC, Maximum
Performance

------------------------------------------------------------------------

# What This Stack Creates

## Networking

-   VCN
-   Internet Gateway
-   NAT Gateway
-   Service Gateway
-   Public Route Table
-   Private Route Table
-   Security List (22, 1521, 5500 open)
-   Public Subnet (for clusters)
-   Backup Subnet (private)

## Database Infrastructure

-   2 × Exascale Storage Vaults, one per selected Availability Domain
-   2 × ExaDB-XS VM Clusters (2-node RAC each), deployed across Availability Domains
-   2 × DB Homes
-   1 × Primary Database (CDB + PDB)
-   1 × Standby Database (created via Data Guard)
-   Data Guard Association (ASYNC, Maximum Performance)

------------------------------------------------------------------------

# Prerequisites

## OCI Requirements

-   Sufficient quota for:
    -   2 × ExaDB-XS VM Clusters
    -   2 × Exascale Storage Vaults
-   IAM permissions:
    -   manage database-family
    -   manage virtual-network-family
    -   manage orm-stacks

------------------------------------------------------------------------

## Grid Infrastructure Image (Critical Requirement)

-   By default, the stack dynamically discovers the Grid Infrastructure
Patch OCID (resource type: dbpatch) for ExaDB-XS using the OCI Terraform
data source `oci_database_gi_version_minor_versions`.

The lookup uses:

-   `gi_version` (default: `23.0.0.0`)
-   `primary_availability_domain`
-   `shape_family = "EXADB_XS"`
-   `compartment_ocid`

If you need to force a specific patch, set `grid_image_id` to a valid
ExaDB-XS Grid Infrastructure image OCID. If `grid_image_id` is empty,
Terraform uses the discovered value.

Example format:

ocid1.dbpatch.oc1.`<region>`{=html}.xxxxx

Important:

-   This OCID is region-specific.
-   It is NOT created by this Terraform stack; it is discovered from OCI
    metadata or supplied as an override.
-   It must be compatible with ExaDB-XS.
-   Deployment will fail if it does not match the selected region.

To retrieve available Grid Infrastructure images:

Using OCI CLI:

oci db patch list\
--compartment-id `<compartment_ocid>`{=html}\
--patch-type GRID_INFRASTRUCTURE\
--region `<region>`{=html}

Or via Console:

Oracle Database → Exadata Infrastructure → Patches

------------------------------------------------------------------------

# Required Inputs

  Variable              Description
  --------------------- -------------------------------------
  compartment_ocid      Target compartment
  primary_availability_domain   AD for primary ExaDB-XS resources
  standby_availability_domain   AD for standby ExaDB-XS resources
  db_admin_password     SYS password (\>=12 chars, complex)
  ssh_public_key        SSH public key for cluster nodes

Optional Grid Infrastructure inputs:

  Variable              Description
  --------------------- -------------------------------------
  gi_version            GI version used for dynamic image lookup (default: 23.0.0.0)
  grid_image_id         Optional Grid Infrastructure patch OCID override

------------------------------------------------------------------------

# Deployment Steps

1.  Go to OCI → Developer Services → Resource Manager
2.  Create Stack
3.  Upload ZIP (main.tf + schema.yaml)
4.  Provide required inputs
5.  Click Plan
6.  Click Apply

Estimated provisioning time: 2--4 hours.

------------------------------------------------------------------------

# Post-Deployment Validation

Check Database Role:

SELECT database_role FROM v\$database;

Primary should show: PRIMARY\
Standby should show: PHYSICAL STANDBY

Check Data Guard processes:

SELECT process, status FROM v\$managed_standby;

Expect: - RFS running - MRP running

------------------------------------------------------------------------

# Important Notes

-   Single-region, cross-Availability-Domain deployment (not cross-region DR).
-   Security list allows inbound from 0.0.0.0/0 (not production
    hardened).
-   Auto-backup is disabled.
-   Protection mode is MAXIMUM_PERFORMANCE.
-   Terraform does not manage runtime switchover/failover state.

------------------------------------------------------------------------

# Destroying the Environment

From Resource Manager:

1.  Open the Stack
2.  Click Destroy

This removes all networking, clusters, DB Homes, databases, and Data
Guard configuration.

Destruction is irreversible.

------------------------------------------------------------------------

# Summary

This stack provisions a complete ExaDB-XS Active Data Guard environment
in a single region across two Availability Domains, including networking and storage.

The stack discovers a valid, region-matching Grid Infrastructure patch
OCID automatically unless `grid_image_id` is supplied as an override.
