This demo, to be used with the tmux-vim-mappings in ../.. runs a step-by-step demo that demonstrates DGPDB creation on a 21.7 environment
provisioned with the terraform stack: dbsystem-rac-dgpdb

```
# new session
tmux new-session -A -s dgpdbconfig

# attach existing
tmux attach -t dgpdbconfig


# vi the tmux files
PgDown : execute current line
F12 : execute from line 1 to current line
F10: execute selected lines 
PgUP : raw send selected text (to select with ^V)
```

The compute instances must be spawn with the Terraform stack in ../../terraform-stacks/dbsystem-rac-dgpdb/
The tmux files must be adapted to use the correct connection strings and DB_UNIQUE_NAMES created by the terraform stack.
