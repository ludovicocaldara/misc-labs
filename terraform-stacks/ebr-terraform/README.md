## EBR Terraform Stack

This Terraform stack provisions everything needed to run the Edition-Based Redefinition (EBR) HR lab without relying on any other stack. In particular, it creates:

- **Networking** – a dedicated VCN with a public subnet, security list rules (SSH, SQL*Net, ICMP), internet gateway, and route table so the lab environment is completely self-contained.
- **Compute** – an Oracle Linux compute instance (shape configurable via variables) that is automatically configured by the provided `conf/setup.sh` bootstrap script.
- **Autonomous Database** – an Always Free Autonomous Database (`demoadb`) plus the corresponding wallet, which is securely copied to the compute instance for client connectivity.

### Consumers

The Edition-Based Redefinition labs under [`ebr-online/`](../../ebr-online) expect this stack to be applied first. Run it to provision the VCN, compute host, and Autonomous Database that the Human Resources and MovieStream demos connect to.

### Independence from the landing-zone stack

This stack is intentionally standalone and **does not depend on the `landing-zone` stack** (or any other Terraform stack) for networking, identity, or shared services. You can deploy it directly in a target compartment using only the variables defined in `variables.tf`.
