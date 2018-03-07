# Launch a Conjur V5 Appliance Cluster

These instructions will run you through the process of launching a small, three node cluster. This cluster will include a Conjur Master, single Standby, and single Follower.

## Configure a Single Conjur Master

Now we'll launch and configure a Conjur master instance. Our master will be configured with the following information:

|||
--- | ---
username | admin
password | secret
account | demo

```sh
$ ./0_start.sh # starts a Conjur Master
$ ./1_configure-master.sh # Configures a Conjur master with the admin password `secret` and the account `demo`
```

Verify Conjur Master is running by navigating to [port 443 on localhost](https://localhost)

Next verify the [Master Health](https://localhost/health)

## Configure a Follower

Next we'll create a follower for our cluster:

```sh
$ ./3_start-and-configure-follower.sh # starts a Conjur Follower
```

Verify our follower is working as expected by viewing the cluster health through the master: [Health](https://localhost/health)


## Configure a Standby

Next we'll create a standby for our cluster:

```sh
$ ./3_3_start-and-configure-standby.sh # starts a Conjur Standby
```

Verify our standby is working as expected by viewing the cluster health through the master: [Health](https://localhost/health)
