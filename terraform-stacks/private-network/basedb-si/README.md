# Base DB (Single Instance – Standalone 23ai)

This stack provisions **one or more standalone single-instance DB Systems** in the same availability domain. No Data Guard association is configured by this stack.

## Prerequisites

- Deploy the [`terraform-stacks/landing-zone`](../landing-zone) stack first. The DB subnet defined here reuses that VCN, private route table (if exported), and the shared **`misc_labs_nsg`** network security group so you can reach the databases from the bastion endpoint.
- Provide the compartment OCID, region, and SSH key via `terraform.tfvars` or environment variables.
- Pass the bastion display name (`bastion_name`) so this stack can look up the OCI Bastion endpoint and expose its subnet CIDR dynamically (handy when applying from OCI Resource Manager without a local landing-zone state file).
- Optionally override `landing_zone_state_path` if the landing-zone state file lives somewhere else. When the landing-zone state isn’t accessible (for example, a separate deployment pipeline), simply pass the IDs exported by that stack via the new override variables: `landing_zone_vcn_id`, `landing_zone_private_route_table_id`, `landing_zone_nat_gateway_id`, `bastion_endpoint_subnet_id`, and `bastion_endpoint_subnet_cidr`.

## What this stack does

1. Reuses the landing-zone networking artifacts either by reading its Terraform state (default) or by consuming the override variables listed above—making this stack work as a satellite deployment where the landing zone lives elsewhere.
2. Creates one private subnet specific to this lab (default `10.50.20.0/24`) and associates it to the landing-zone route table (or creates a simple NAT-backed one when absent).
3. Provisions **standalone DB Systems** (`db_system_count = 1` by default) with Oracle Database 26ai, single-node shapes, and your supplied SSH key so you can log in via the bastion.

After `terraform apply` completes, connect through the bastion host exported by the landing zone and use the created DB systems as independent environments.

This stack also exports `bastion_endpoint_cidr`, which reflects the OCI Bastion subnet CIDR discovered at runtime—use it to scope client allow lists or security rules consistently across stacks.
