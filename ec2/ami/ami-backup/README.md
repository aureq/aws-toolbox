aws-toolbox/ec2/ami/ami-backup
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
The files included in this folder and its subfolders are here to help you automate the creation of an Amazon Machine Image (AMI) using the Amazon Command Line Interface(1).

In addition of creating AMIs, the creation script offers the ability to set an expiry date (or a retention period).
Once an AMI has expired, the cleanup script will deregister your AMI and delete associated snapshots.
If an AMI has been deregistered, then each orphan snapshots are checked. An orphan snapshot is deleted only after it has expired.

For off-site backup and regulatory compliance, you may also send a copy of your AMI to a different region.
The same expiry policy will be applied.

## Features ##
* Takes an AMI of an EC2 instance, from any region
* Applies tags to easy identification
* Adds expiry tag to enforce retention policy
* Supports cross-region copy of your AMI
* Can be executed from anywhere as long as you have internet access

## Requirements ##
The scripts require very few things to work.
* The AWS Command Line Interface(1)
 * (`apt-get`|`yum`) `install` (`awscli`|`aws-cli`)
* The `jq` tool
 * (`apt-get`|`yum`) `install jq`

## Installation ##
You can deploy the scripts using the installation script `install.sh`. While the scripts will be overwritten, the cron file won't.

## Configuration ##
The first thing you need to create is an IAM user(3). The user does not require a password, but you will need its access key and its secret key. 
Also, make sure you apply the IAM policy as stored in `iam_policy.json`. This will grant your user the sufficient rights to perform the actions.

The second step is to configure the AWS Command Line Interface. While you may not need to create a profile, it's recommended. To do so, simply run the following command: `aws configure --profile ami-backup` and then follow the prompt.

The third step is to configure when the scripts will be run and an eventual retention policy. Please refer to the content of `etc/cron.d/amicron`

## Scripts ##
- `usr/bin/image-instance.sh`: Create an AMI for the local instance or the instance specified by `-i`. You may specify the retention period by appending a date or a period as specified by the date(4) command. Possible examples are `'+1 week'`, `'next month'` or `'42 days'`. Call the script with `-h` for a complete list of options.
- `usr/bin/purge-expired-amis.sh`: This script deregisters all your expired AMIs and the associated snapshots. Call the script with `-h` for a complete list of options.

### Options for `image-instance.sh` ###
Here is a detailed description of each option available for `image-instance.sh`
* `-p profile_name`: The `aws` profile name that was configured above. The default profile is `default`. This option determines which profile will be used and hence which set of IAM credentials will be used when sending queries to AWS.
* `-i instance_id`: This allows you to specify the instance ID you want to backup. If this parameter is omitted, the script will try to guess the local instance ID by sending a query to the meta-data server.
* `-r region`: Indicates in which AWS region the specified instance (`-i`) is running from. If this parameter is omitted, the script will query the meta-data server to determine the local region.
* `-e expiry_date`: The script has the ability to tag the resulting AMI and set an expiry date. Possible values are `'+1 week'`, `'next month'` or `'42 days'`. This allows you to enforce a retention policy on your AMI. If the parameter is not specified, then no tag is applied and your AMI will not be purged.
* `-d region`: when specified, this option allows you to copy the resulting AMI to a different `region`. The copied AMI automatically inherits any existing tags. If the parameter is omitted, then no copy of the AMI is performed. You may consider this option carefully at extra data transfer may be applied to your AWS account.
* `-t timeout`: When an AMI copy is initiated, it may take a while to fully complete depending on the AMI size. This defines an acceptable time-out before the script stops. The default value is `28800` (8 hours), but you may increase is for larger AMIs.

## Feature requests ##
You're welcome to request more features regarding these scripts, though I may not implement all of them as I develop and maintain these scripts on my spare time. You are also invited to issue a pull request with a meaningful description of your changes.

## Acknowledgement ##
* Thanks to Colin for suggesting me this tool.
* Thanks to David L. for raising a bug and his suggestion to purge the orphan snapshots
* Thanks to John for requesting the cross-region copy

#### Resources ####
1. AWS CLI: http://aws.amazon.com/cli/
2. JQ homepage: http://stedolan.github.io/jq/
3. Creating an IAM user: http://docs.aws.amazon.com/IAM/latest/UserGuide/Using_SettingUpUser.html
4. Manpage for date: http://linux.die.net/man/1/date
