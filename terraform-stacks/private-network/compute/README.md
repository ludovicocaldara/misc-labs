# Compute Stack (requires Landing Zone)

This stack one or many compute instances, along with a dedicated subnet and network rules accessible from the landing zone.

## Prerequisites

- Deploy the [`terraform-stacks/landing-zone`](../landing-zone) stack first.
- Provide `compartment_ocid`, `region`, and `ssh_public_key`.
- Ensure a bastion named `${landing_zone_name}-bastion` exists in the target compartment.

## What this stack does

1. Dynamically discovers landing-zone networking artifacts by display name:
   - `${landing_zone_name}-vcn`
   - `${landing_zone_name}-rt-private`
   - `${landing_zone_name}-nat`
   - `${landing_zone_name}-subnet-bastion-endpoint`
2. Creates a lab private subnet derived from landing-zone CIDR via `cidrsubnet(..., 8, lab_number)`.
3. Creates a dedicated NSG and ingress rules from bastion endpoint subnet CIDR for configured TCP ports.
4. Provisions `num_compute` compute instances in the selected AD on the private subnet.

## Main inputs

- `num_compute`: number of compute instances to create.
- `compute_shape`, `shape_ocpus`, `shape_memory_in_gbs`: compute sizing.
- `image_ocid` (optional): explicit image; if omitted, latest Oracle Linux image for selected shape/OS filters is used.
- `bastion_allowed_tcp_ports_csv`: comma-separated list of inbound TCP ports from bastion endpoint subnet (e.g. `22,1521`).

### Example

```hcl
bastion_allowed_tcp_ports_csv = "22,1521,3389"
```
