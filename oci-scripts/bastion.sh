oci bastion session create-managed-ssh \
  --bastion-id ocid1.bastion.oc1.uk-london-1.amaaaaaaknuwtjiaxvau3qqmiugkdp4eq6fh72dp5puik3aexdr6kkinugra \
  --target-private-ip 10.50.2.67 \
  --target-port 22 \
  --ssh-public-key-file ~/.ssh/id_ed25519.pub \
  --target-os-username opc \
  --target-resource-id ocid1.dbnode.oc1.uk-london-1.anwgiljrknuwtjiataag7c6jb4fh7ue6pyxxbp5cwbb6jzdomsiiilrwv4nq \
  --session-ttl 7200 \
  --display-name "ssh-to-lab" \
  --debug
