# DGPDB on ExaDB-XS RAC

This demo prepares a Data Guard per Pluggable Database (DGPDB) Broker
configuration across the two RAC CDBs created by the
[`exaxs-rac-dgpdb` Terraform stack](../../../terraform-stacks/exaxs-rac-dgpdb).
It covers node access, Broker prerequisites, Oracle Net connectivity, client
wallets, and `PREPARE DGPDB`.

## 1. Provision the stack

Provision the Terraform stack with OCI Resource Manager or Terraform. Set the
stack's `ssh_public_key` to the public key matching the private key used by the
tmux runner.

## 2. Create the demo variables

The helper uses the OCI CLI and your configured OCI credentials to read the
deployment through OCI service APIs. It does not connect to the database
nodes. The OCI CLI must be installed and configured for the deployment's
region, with permission to read Resource Manager stack state, databases,
ExaDB-XS VM clusters, database nodes, and their network IPs.

Use either the Resource Manager stack OCID:

```shell
python3 create-vars.py --stack-ocid ocid1.ormstack...
```

Or pass the database OCIDs in Cluster A then Cluster B order:

```shell
python3 create-vars.py --database-ocids ocid1.database... ocid1.database...
```

Add `--profile PROFILE` or `--region REGION` when the default OCI CLI profile
does not select the target deployment. The SSH private-key option defaults to
`-i ~/.ssh/id_rsa`; override it with `--ssh-key-option`. The helper writes the
ignored `vars.json.nogit` next to the script. It contains deployment
connection details and the CDB/PDB names read from OCI, not database
passwords.

## 3. Start tmux-demo-runner

Install the [tmux-demo-runner](https://github.com/ludovicocaldara/tmux-demo-runner)
as a VS Code extension or Vim plugin. In a terminal on the machine where it is
installed, start a session:

```shell
tmux new-session -A -s exaxs-rac-dgpdb
```

Open `exaxs-rac-dgpdb.tmux` with the runner. `PgDown` executes the current line
or selection; `PgUp` sends the selection as raw text.

## Scope

The playbook prepares two independent RAC CDBs as a DGPDB Broker configuration
and validates wallet-based remote SYS connections. It ends after
`PREPARE DGPDB`; add or migrate application PDBs in a separate workflow.

Run the playbook once per deployment. It appends Oracle Net settings and
creates client wallets on the shared ACFS paths used by each cluster.
