This demo, to be used with the tmux-vim-mappings in ../.. runs a step-by-step demo that demonstrates:
* DG creation
* Switchover
* TAC
* Real-time Apply 
* DML redirection
* Automatic Block Repair
* Far Sync

```
# new session
tmux new-session -A -s dgconfig

# attach existing
tmux attach -t dgconfig


# vi the tmux files
PgDown : execute current line
F12 : execute from line 1 to current line
F10: execute selected lines 
PgUP : raw send selected text (to select with ^V)
```

The compute instances must be spawn with the Terraform stack in ../../terraform-stacks/dbsystem-si-manual/
The tmux files must be adapted to use the correct connection strings and DB_UNIQUE_NAMES created by the terraform stack.

