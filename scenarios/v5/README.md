# Conjur V5 Appliance

This section provides an overview of examples running the Conjur V5 appliance.  For a detailed understanding of progress on V5 functionality, please refer to the [Release Notes](https://github.com/conjurinc/appliance/blob/master/RELEASE_NOTES.md) for a more detailed understanding of progress on the migration to V5.

### Beta Release Goal
Software is a highly collaborative effort. We need the help of the larger organization to help us build the best, most usable piece of software possible.  

Please run through this demo, and start to play with V5. If you have questions, comments, complaints, or requests, connect with the team on the ConjurHQ Slack channel #appliance-v5. You're feedback will be incorporated into the development and demo effort.

### Demos
* [Conjur Cluster](cluster/) - Creates a simple Conjur cluster (master, single standby, and follower)

| Script | Effect                                                 |
| ------ | ------------------------------------------------------ |
| [0_start.sh](./cluster/0_start.sh) | ASKS BEFORE DESTROYING ANY RUNNING DEMO ENVIRONMENT - pulls down and loads Conjur v5 appliance image (if needed), brings up uninitialized Conjur v5 Master container |
| [1_configure-master.sh](./cluster/1_configure_master.sh) | Configures running master container |
| [2_start-and-configure-follower.sh](./cluster/2_start-and-configure-follower.sh) | Brings up and configures Follower container |
| [3_start-and-configure-standby.sh](./cluster/3_start-and-configure-standby.sh) | Brings up and configures Standby container |
| [inspect-cluster.sh](./cluster/inspect-cluster.sh) | Displays current cluster configuration info |
