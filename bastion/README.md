# Bastion Tutorial

* Bring up 3 machines: `vm0: conjur`, `vm1: bastion`, `vm2: inventory`.
* **bastion** This is the bastion server. It is reachable from any IP, and all users have user-level access to it. The `operations` group has root-level acess to it.
* **inventory** This is the `inventory` application server. It is only reachable from the bastion IP. The `developers` group has root-level access to it. 
* Run the script `./1_policy.sh` to load the base policies.
* Run `./2_setup_ssh.sh` to Conjurize the bastion and inventory servers.
    - Host identities are created with host factory tokens.
    - HF tokens can be managed through the UI.
* Observe the following:
    - `otto` can SSH to the bastion or to the inventory server, with `sudo` access.
    - `donna` can SSH to the bastion, without `sudo`. `donna` can SSH to the inventory server through the bastion, with `sudo` access to the inventory server.
    - Both users will jump through the bastion to the `inventory` host.

# TODO

* The `inventory` machine needs a firewall rule (iptables?) which makes it unreachable except through the bastion.
