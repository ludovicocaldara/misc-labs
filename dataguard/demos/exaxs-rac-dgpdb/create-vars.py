#!/usr/bin/env python3
"""Create tmux-demo-runner vars from OCI Resource Manager or Database OCIDs."""

import argparse
import json
import subprocess
import sys
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--stack-ocid", help="OCI Resource Manager stack OCID")
    source.add_argument(
        "--database-ocids",
        nargs=2,
        metavar=("CLUSTER_A_DB_OCID", "CLUSTER_B_DB_OCID"),
        help="the two OCI database OCIDs, in Cluster A then Cluster B order",
    )
    parser.add_argument("--profile", help="OCI CLI profile (defaults to DEFAULT)")
    parser.add_argument("--region", help="OCI region; defaults to the selected profile")
    parser.add_argument("--config-file", help="OCI CLI config file")
    parser.add_argument(
        "--ssh-key-option",
        default="-i ~/.ssh/id_rsa",
        help="SSH option inserted into the tmux commands (default: %(default)s)",
    )
    return parser.parse_args()


def oci_command(args, *command, raw=False):
    """Run one read-only OCI CLI command, which calls the OCI service APIs."""
    full_command = ["oci", *command]
    if args.profile:
        full_command.extend(["--profile", args.profile])
    if args.region:
        full_command.extend(["--region", args.region])
    if args.config_file:
        full_command.extend(["--config-file", args.config_file])
    if not raw:
        full_command.extend(["--output", "json"])

    result = subprocess.run(full_command, capture_output=True, text=True, check=False)
    if result.returncode:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(detail or f"OCI CLI exited with status {result.returncode}")
    return result.stdout


def oci_json(args, *command):
    response = json.loads(oci_command(args, *command))
    if "data" not in response:
        raise RuntimeError(f"OCI CLI response did not include data: {' '.join(command)}")
    return response["data"]


def field(record, name):
    """Read a CLI JSON property across snake_case and kebab-case spellings."""
    wanted = name.replace("-", "_").lower()
    for key, value in record.items():
        if key.replace("-", "_").lower() == wanted:
            return value
    return None


def ids_from_stack_state(args, stack_ocid):
    state_text = oci_command(
        args,
        "resource-manager",
        "stack",
        "get-stack-tf-state",
        "--stack-id",
        stack_ocid,
        "--file",
        "-",
        raw=True,
    )
    state = json.loads(state_text)
    outputs = state.get("outputs", {})
    try:
        return (
            outputs["dgpdb1_database_id"]["value"],
            outputs["dgpdb2_database_id"]["value"],
        )
    except (KeyError, TypeError) as exc:
        raise RuntimeError(
            "The stack state does not contain dgpdb1_database_id and "
            "dgpdb2_database_id outputs. Apply the exaxs-rac-dgpdb stack first."
        ) from exc


def database_details(args, database_ocid):
    return oci_json(args, "db", "database", "get", "--database-id", database_ocid)


def node_public_ip(args, node_id):
    node = oci_json(args, "db", "node", "get", "--db-node-id", node_id)
    host_ip_id = field(node, "host_ip_id")
    if not host_ip_id:
        hostname = field(node, "hostname") or node_id
        raise RuntimeError(f"OCI returned no host IP OCID for database node {hostname}.")

    public_ip = oci_json(
        args,
        "network",
        "public-ip",
        "get",
        "--private-ip-id",
        host_ip_id,
    )
    address = field(public_ip, "ip_address")
    if not address:
        hostname = field(node, "hostname") or node_id
        raise RuntimeError(f"OCI returned no public IP address for database node {hostname}.")
    return address


def cluster_details(args, database):
    cluster_id = field(database, "vm_cluster_id")
    compartment_id = field(database, "compartment_id")
    if not cluster_id or not compartment_id:
        raise RuntimeError("OCI database details did not include its VM cluster and compartment OCIDs.")
    pdb_name = field(database, "pdb_name")
    if not pdb_name:
        db_unique_name = field(database, "db_unique_name") or field(database, "id")
        raise RuntimeError(f"OCI database details did not include the PDB name for {db_unique_name}.")

    cluster = oci_json(
        args,
        "db",
        "exadb-vm-cluster",
        "get",
        "--exadb-vm-cluster-id",
        cluster_id,
    )
    scan_dns_name = field(cluster, "scan_dns_name")
    domain = field(cluster, "domain")
    if not scan_dns_name or not domain:
        raise RuntimeError(f"OCI returned incomplete SCAN or domain details for VM cluster {cluster_id}.")

    nodes = oci_json(
        args,
        "db",
        "node",
        "list",
        "--compartment-id",
        compartment_id,
        "--vm-cluster-id",
        cluster_id,
        "--all",
    )
    available_nodes = [
        node for node in nodes
        if field(node, "lifecycle_state") in (None, "AVAILABLE")
    ]
    available_nodes.sort(key=lambda node: field(node, "hostname") or field(node, "id") or "")
    if len(available_nodes) != 2:
        raise RuntimeError(
            f"Expected two AVAILABLE database nodes in VM cluster {cluster_id}; "
            f"OCI returned {len(available_nodes)}."
        )

    return {
        "host1": {"public_ip": node_public_ip(args, field(available_nodes[0], "id"))},
        "host2": {"public_ip": node_public_ip(args, field(available_nodes[1], "id"))},
        "dgpdb": {
            "dbun": field(database, "db_unique_name"),
            "dbname": field(database, "db_name"),
            "pdb_name": pdb_name,
        },
        "scan_dns_name": scan_dns_name.rstrip("."),
        "domain": domain.rstrip("."),
    }


def main():
    args = parse_args()
    if args.stack_ocid:
        database_ocids = ids_from_stack_state(args, args.stack_ocid)
    else:
        database_ocids = args.database_ocids

    databases = [database_details(args, ocid) for ocid in database_ocids]
    if field(databases[0], "vm_cluster_id") == field(databases[1], "vm_cluster_id"):
        raise RuntimeError("The two database OCIDs must belong to different RAC VM clusters.")

    variables = {
        "demo_name": "DGPDB on ExaDB-XS RAC",
        "presenter": "Ludo",
        "public_key": args.ssh_key_option,
        "clu1": cluster_details(args, databases[0]),
        "clu2": cluster_details(args, databases[1]),
    }
    output = Path(__file__).with_name("vars.json.nogit")
    output.write_text(json.dumps(variables, indent=2) + "\n", encoding="utf-8")
    print(f"Created {output}")


if __name__ == "__main__":
    try:
        main()
    except (FileNotFoundError, json.JSONDecodeError, RuntimeError) as error:
        print(f"Error: {error}", file=sys.stderr)
        sys.exit(1)
