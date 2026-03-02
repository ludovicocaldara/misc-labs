# Edition-Based Redefinition Examples

This directory contains multiple Edition-Based Redefinition (EBR) demo applications:

* [**human-resources**](ebr-human-resources/README.md)
  * The classic HR sample schema, revisited to showcase EBR lifecycle management.
* [**moviestream**](ebr-moviestream/README.md)
  * A streaming-style app that demonstrates multi-edition rollouts at a larger scale.

## Terraform prerequisite

Both applications rely on the Terraform stack under [`../terraform-stacks/ebr-terraform`](../terraform-stacks/ebr-terraform/README.md). Apply it before working with either demo:

* **Prerequisite** – That stack provisions all required OCI resources (VCN, compute host, Autonomous Database, wallet copy) for the EBR labs. Run it first to obtain the infrastructure the apps expect.
* **Self-standing** – The stack creates its own Virtual Cloud Network and supporting components, so it does **not** require the base landing-zone or shared networking modules.
