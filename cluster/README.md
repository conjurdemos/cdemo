# adds standbys to cluster and shows failover
  - 0-setup-cluster.sh - brings cluster to default state of 1-master/2-standbys/1-follower
  - 1-cluster-failover.sh - removes current master to trigger auto-failover, adds replacement standy
