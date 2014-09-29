aws-toolbox/ec2/ebs/snapshot
=========

## Audience ##
This documentation and the associated scripts are intended for system administrator that are using EC2 instances from Amazon Web Services.

## License ##
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

## Description ##
The files included in this folder and its subfolders are here to help you automate the creation of EBS snapshots using the Amazon Command Line Interface(1).

In addition of taking snapshots of your EBS volumes, the creation script offers the ability to set an expiry date (or a retention period).

Once the snapshot has expired, the cleanup script will delete it.

## Requirements ##
The scripts require very few things to work.
* The AWS Command Line Interface(1)
 * (`apt-get`|`yum`) `install awscli`
* The `jq` tool
 * (`apt-get`|`yum`) `install jq`

## Installation ##
You can deploy the scripts using the installation script `install.sh`. While the scripts will be overwritten, the cron file won't.

## Configuration ##
The first thing you need to create is an IAM user(3). The user does not require a password, but you will need its access key and its secret key. 
Also, make sure you apply the IAM policy as stored in `iam_policy.json`. This will grant your user the sufficient rights to perform the actions.

The second step is to configure the AWS Command Line Interface. While you may not need to create a profile, it's recommended. To do so, simply run the following command: `aws configure --profile ebs-backup` and then follow the prompt.

The third step is to configure when the scripts will be run and an eventual retention policy. Please refer to the content of `etc/cron.d/snapshotcron`

## Scripts ##
- `usr/bin/snapshot-instance-volumes.sh`: This script when run from an EC2 instance retrieves the instance meta-data and then get all the associated volumes. Once all the volumes are known for this instance, a snapshot is taken and some tags are linked to that new snapshot so you can easily. Additionally, you may pass an "expiration" date on your snapshot `snapshot-instance-volumes.sh '+1 week'`. This will add an extra tag to your snapshot that will be used by `usr/bin/purge-expired-snapshots.sh`
- `usr/bin/purge-expired-snapshots.sh`: This script checks all the snapshots that have the "Expire" tag and if the stored date is in the past, the snapshot is deleted. This scripts clean `all` expired snapshots regardless of the instance-id for all your regions.
- `etc/cron.d/snapshotcron`: This file holds the cron settings and should be placed in /etc/cron.d/ I've added some examples in there to get you started more easily.

## Feature requests ##
You're welcome to request more features regarding these scripts, though I may not implement all of them as I develop and maintain these scripts on my spare time. You are also invited to issue a pull request with a meaningful description of your changes.

#### Resources ####
1. AWS CLI: http://aws.amazon.com/cli/
2. JQ homepage: http://stedolan.github.io/jq/
