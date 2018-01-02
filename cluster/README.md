# adds standbys to cluster and shows failover
  - 0-setup-cluster.sh - brings stateful sub-cluster to default of 1-master/2-standbys
  - 1-cluster-failover.sh - removes current master to trigger auto-failover, calls 0-setup-cluster to replace standby
