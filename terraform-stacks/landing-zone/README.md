# Landing Zone Terraform Stack

Use this folder to deploy the base landing zone networking components. Configuration is driven via Terraform variables:

- `terraform.tfvars.sample` – copy this file to `terraform.tfvars` and fill in the required OCIDs.
- `schema.yaml` – provides a structured view of the inputs so you can focus on the mandatory values first (Core OCI Authentication and Target Compartment). Optional defaults are hidden by default and can be expanded when customization is needed.

Once your variables are set, run the usual Terraform workflow:

```sh
terraform init
terraform plan
terraform apply
```

> Tip: keep the schema and sample tfvars in sync if you introduce new variables.

## Connecting via the Bastion Host

This landing zone stack also provisions the shared bastion host that other labs in this repository rely on. Many of those labs spin up private subnets without direct internet access; the bastion gives you a consistent jumping point into those environments so you can manage compute instances, databases, or application services securely.

### Prerequisites

- Confirm the bastion public IP from the Terraform outputs (or the OCI console).
- Ensure your SSH private key matches the public key configured in `terraform.tfvars`.
- Verify that any downstream lab has added its target instance to a subnet reachable from the bastion.

### Basic SSH Access

```sh
ssh -i ~/.ssh/oci_lab_key opc@<bastion_public_ip>
```

Once connected, you can reach resources that reside in the private subnets created by other labs.

### Port Forwarding Examples

Use SSH port forwarding when you need to reach services bound to private IPs:

```sh
# Forward local port 1521 to a private database listener
ssh -i ~/.ssh/oci_lab_key -L 1521:<db_private_ip>:1521 opc@<bastion_public_ip>

# Forward local port 8000 to a private web app or API server
ssh -i ~/.ssh/oci_lab_key -L 8000:<app_private_ip>:8000 opc@<bastion_public_ip>
```

After running the SSH command, point your local tooling (SQL*Plus, SQL Developer, browsers, curl, etc.) to `localhost:<forwarded_port>` and traffic will traverse the bastion into the private subnet.



oci bastion bastion list -c  $COMPID     
oci compute compute-host list -c $COMPID
oci db database list -c $COMPID    
oci db node list -c $COMPID --db-system-id <get dynamically from oci db database list>
oci network vnic get --vnic-id <get dynamically from oci db node list>