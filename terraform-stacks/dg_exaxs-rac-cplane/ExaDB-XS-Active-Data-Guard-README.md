# ExaDB-XS End-to-End (Active Data Guard)

Provision a complete Oracle ExaDB-XS Active Data Guard environment using
OCI Resource Manager.

This stack creates:

-   Full VCN networking
-   Exascale Storage Vault
-   Two ExaDB-XS RAC VM Clusters
-   Two DB Homes
-   One Primary CDB
-   One Standby CDB (via Data Guard)
-   Optional Active Data Guard (read-only standby)

> Single-region deployment (both clusters in same Availability Domain)

------------------------------------------------------------------------

## Architecture Overview

VCN ├── Public Subnet │ ├── ExaDB-XS Cluster A (Primary) │ └── ExaDB-XS
Cluster B (Standby) │ └── Backup Subnet (Private)

Shared Exascale Storage Vault

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

-   Exascale Storage Vault
-   2 × ExaDB-XS VM Clusters (2-node RAC each)
-   2 × DB Homes
-   1 × Primary Database (CDB + PDB)
-   1 × Standby Database (created via Data Guard)
-   Data Guard Association (ASYNC, Maximum Performance)

------------------------------------------------------------------------

# Prerequisites

## OCI Requirements

-   Sufficient quota for:
    -   2 × ExaDB-XS VM Clusters
    -   Exascale Storage Vault
-   IAM permissions:
    -   manage database-family
    -   manage virtual-network-family
    -   manage orm-stacks

------------------------------------------------------------------------

## Grid Infrastructure Image (Critical Requirement)

The variable `grid_image_id` must be set to a valid Grid Infrastructure
Patch OCID (resource type: dbpatch).

Example format:

ocid1.dbpatch.oc1.`<region>`{=html}.xxxxx

Important:

-   This OCID is region-specific.
-   It is NOT created by this Terraform stack.
-   It must already exist in OCI.
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
  availability_domain   AD for ExaDB-XS
  grid_image_id         Grid Infrastructure patch OCID
  db_admin_password     SYS password (\>=12 chars, complex)
  ssh_public_key        SSH public key for cluster nodes

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

-   Single-region deployment (not cross-region DR).
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
in a single region, including networking and storage.

The only external dependency is a valid, region-matching Grid
Infrastructure patch OCID.
