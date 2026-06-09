# Compute Public Stack (requires Landing Zone)

This stack creates one or many compute instances inside an existing landing-zone subnet (no new subnet is created by this stack).

## Prerequisites

- Deploy the [`terraform-stacks/landing-zone`](../landing-zone) stack first.
- Provide `compartment_ocid`, `region`, and `ssh_public_key`.
- Ensure a bastion named `${landing_zone_name}-bastion` exists in the target compartment.

## What this stack does

1. Dynamically discovers landing-zone networking artifacts by display name:
   - `${landing_zone_name}-vcn`
   - `${landing_zone_subnet_name}`
   - `${landing_zone_name}-subnet-bastion-endpoint`
2. Reuses the existing landing-zone subnet selected through `landing_zone_subnet_name`.
3. Creates a dedicated NSG and ingress rules from bastion endpoint subnet CIDR for configured TCP ports.
4. Provisions `num_compute` compute instances in the selected AD on that existing subnet.
5. Requests public IPs only when the selected subnet allows them (`prohibit_public_ip_on_vnic = false`).

## Main inputs

- `landing_zone_subnet_name`: display name of the existing landing-zone subnet where instances are attached.
- `num_compute`: number of compute instances to create.
- `compute_shape`, `shape_ocpus`, `shape_memory_in_gbs`: compute sizing.
- `image_ocid` (optional): explicit image; if omitted, latest Oracle Linux image for selected shape/OS filters is used.
- `bastion_allowed_tcp_ports_csv`: comma-separated list of inbound TCP ports from bastion endpoint subnet (e.g. `22,1521`).

### Example

```hcl
bastion_allowed_tcp_ports_csv = "22,1521,3389"
```
