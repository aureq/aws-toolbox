aws-toolbox/ec2/ebs/snapshot
=========

This folder contains 2 scripts to help you automate the snapshot creation from within an EC2 instance

  - `usr/bin/snapshot-instance-volumes.sh`: This script when run from an EC2 instance retrieves the instance meta-data and then get all the associated volumes. Once all the volumes are known for this instance, a snapshot is taken and some tags are linked to that new snapshot so you can easily. Additionally, you may pass an "expiration" date on your snapshot `snapshot-instance-volumes.sh '+1 week'`. This will add an extra tag to your snapshot that will be used by `usr/bin/purge-expired-snapshots.sh`
  - `usr/bin/purge-expired-snapshots.sh`: This script checks all the snapshots that have the "Expire" tag and if the stored date is in the past, the snapshot is deleted. This scripts clean `all` expired snapshots regardless of the instance-id for all your regions.
  - `etc/cron.d/snapshotcron`: This file holds the cron settings and should be placed in /etc/cron.d/ I've added some examples in there to get you started more easily.

In order to complete the installation, you will need:

  * to install "jq"(2) which is required to parse the json data returned by the AWS CLI. `sudo apt-get install jq -y`
  * to ensure the AWS CLI is configured correctly and has the correct credentials(3). `aws configure`

You may also want to create a dedicated IAM user, retrieve its access/secret key and assign the policy as attached in `iam_policy.json`.

#### Resources ####
1. JQ homepage: http://stedolan.github.io/jq/
2. AWS CLI: http://aws.amazon.com/cli/
