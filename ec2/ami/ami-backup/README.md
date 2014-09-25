aws-toolbox/ec2/ami/ami-backup
=========

This folder contains 2 scripts to help you automate the ami creation from within an EC2 instance

  - `usr/bin/image-insatnce.sh`: This script when run from an EC2 instance retrieves the instance-id if not instance-id has been provided, then creates an Amazon Machine Image (AMI). Once the AMI has been created, the script adds various tags so the AMI and the associated snapshots can be more easily identified and reused. Additionally, you may pass an "expiration" date on your AMI `image-instance.sh '+1 week'`. This will add an extra tag that will be used by `usr/bin/purge-expired-amis.sh`
  - `usr/bin/purge-expired-amis.sh`: This script checks all the AMIs that have the "Expire" tag and if the stored date is in the past, the AMI is deleted. This scripts clean `all` expired AMIs and associated snapshots regardless of the instance-id. You may specify one or more region you want to check and purge as needed.
  - `etc/cron.d/amicron`: This file holds the cron settings and should be placed in /etc/cron.d/ I've added some examples in there to get you started more easily.

In order to complete the installation, you will need:

  * to install "jq"(2) which is required to parse the json data returned by the AWS CLI. `sudo apt-get install jq -y`
  * to ensure the AWS CLI is configured correctly and has the correct credentials(3). `aws configure`

You may also want to create a dedicated IAM user, retrieve its access/secret key and assign the policy as attached in `iam_policy.json`.

#### Resources ####
1. JQ homepage: http://stedolan.github.io/jq/
2. AWS CLI: http://aws.amazon.com/cli/
