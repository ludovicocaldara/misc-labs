# Oracle Data Guard Redo Transport TLS Authentication

This demo, to be used with the [tmux-demo-runner](https://github.com/ludovicocaldara/tmux-demo-runner) runs a step-by-step demo that sets up TLS authentication for the redo transport.
This capability is supported since Oracle AI Database version 23.26.2.0.0.
It requires an environment provisioned with the terraform stack: public-network/dg-basedb-si-cplane with one standby database.

## Step 1: Provision the terraform stack

Using OCI Resource Manager or your preferred Terraform runtime, provision the stack [dg-basedb-si-cplane](terraform-stacks/public-network/dg-basedb-si-cplane).

## Step 2: Install the tmux-demo-runner 

The [tmux-demo-runner](https://github.com/ludovicocaldara/tmux-demo-runner) can be installed as a VScode extension (handy to directly access the machines via SSH), or as a vim plugin (best if you don't have direct SSH access from your machine).

## Step 3: Start a tmux session where the tmux-demo-runner is installed

```shell
# new session
tmux new-session -A -s tls-redo

# attach existing
tmux attach -t tls-redo
```

## Step 3: Customize the variables

Copy the variable file and replace the IP addresses with your actual IPs.

```shell
cp tls-redo-authentication-vars.json tls-redo-authentication-vars.json.nogit
```

## Step 4: Open the editor and run the demo

```shell
vi tls-redo-authentication.tmux
# vi the tmux file tls-redo-authentication.tmux, or open it with vscode and by installing the tmux-demo-runner vscode extension.
PgDown : execute current line or the selection
PgUP : raw send selected text (to select with ^V)
```

The variable file is read with the first line and the substitutions will happen automatically.
