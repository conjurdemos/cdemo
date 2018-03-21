# Conjur V5 Appliance

This section provides an overview of examples running the Conjur V5 appliance.  For a detailed understanding of progress on V5 functionality, please refer to the [Release Notes](https://github.com/conjurinc/appliance/blob/master/RELEASE_NOTES.md) for a more detailed understanding of progress on the migration to V5.

### Beta Release Goal
Software is a highly collaborative effort. We need the help of the larger organization to help us build the best, most usable piece of software possible.  

Please run through this demo, and start to play with V5. If you have questions, comments, complaints, or requests, connect with the team on the ConjurHQ Slack channel #appliance-v5. You're feedback will be incorporated into the development and demo effort.

### Get a V5 Image

To begin, you'll need access to the Conjur V5 appliance image. We can retrieve this image either from an S3 bucket or our internal Docker repository.

#### Download an image from S3:
```sh
$ curl 'https://s3.amazonaws.com/appliance-v5-dev.conjur.org/conjur-appliance%3A5.0.0-alpha.1.tar.gz?AWSAccessKeyId=AKIAIFJWM5FD6QYF5QDA&Expires=1521732748&Signature=%2BMIx2%2Fv8QfaxRFP4l8dXBRJtYUU%3D' | gunzip | docker load
```

#### Download from Conjur Docker Repository
```sh
$ docker pull registry.tld/conjur-appliance:5.0-stable
```


### Demos
* [Conjur Cluster](cluster/) - Creates a simple Conjur cluster (master, single standby, and follower)
