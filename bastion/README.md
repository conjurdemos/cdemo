# Bastion Tutorial

- 0-setup-bastion.sh - Brings up 3 machines:
  - outside_vm - ubuntu container on separate network from all others - can only reach the bastion_server
  - bastion_server - proxy for access to designated VMs in network. All users have SSH access to it. The sec_ops group has sudo access to it.
  - protected_vm - VM accessible via SSH through bastion_server. All users have SSH and sudo access to it.
- 1-exec-to-outside-vm.sh - execs into outside_vm, where you can "su -" to one of the users
  - "su - carol", ping bastion_server to show connectivity, then ping conjur_master, conjur_follower etc.
  - ssh protected_vm - will ssh through bastion_server to protected_vm
  - exit, then "su - ted", show how ted can't access either the bastion_server or protected_vm
  - all access is governed by Conjur policy with no need to distribute SSH keys
  - Users' SSH configuration is standard .ssh

