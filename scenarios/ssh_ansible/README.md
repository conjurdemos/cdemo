# SSH demo directory

  - 0-setup-ssh.sh - takes 1 argument for # of "rack VMs" to bring up, configures each w/ Chef cookbook
  - 1_create_key_for_user.sh - takes 1 argument (user name) - creates SSH key for given user and stored pub key in Conjur
  - 2_test_fetch_userkey_from_host.sh - takes 2 arguments (user, container name) - tests if container can fetch user's pub key
  - 3_ssh_user_to_host.sh - takes 2 arguments (user, container) - attempts to ssh as user to container/host
  - 4_roles_with_resource_permissions.sh - takes 2 arguments (host:container, privilege) - shows all roles holding privilege on resource - 5_review_activity_on_resource.sh - takes 1 argument (host:container) - displays audit records for resource - rack.yml - policy file created and loaded by 0-setup-ssh.sh - load_policy.sh - utility for loading ssh-mgmt.yml during demo to effect access changes - ssh-mgmt.yml - defines access policies for Dev and Prod VM access
