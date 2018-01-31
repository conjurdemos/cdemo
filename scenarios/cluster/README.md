# adds standbys to cluster and (for Conjur 4.9.10 and above) shows failover
  - 0-setup-cluster.sh - brings stateful sub-cluster (1-master/2-standbys)
  - 1-cluster-failover.sh - removes current master to trigger auto-failover, reconfigured failed master as a standby
