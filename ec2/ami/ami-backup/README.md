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

Once an AMI has expired, the cleanup script will deregister your AMI and delete the subsequent snapshots.

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

The second step is to configure the AWS Command Line Interface. While you may not need to create a profile, it's recommended. To do so, simply run the following command: `aws configure --profile ami-backup` and then follow the prompt.

The third step is to configure when the scripts will be run and an eventual retention policy. Please refer to the content of `etc/cron.d/amicron`

## Scripts ##
- `usr/bin/image-instance.sh`: Create an AMI for the local instance or the instance specified by `-i`. You may specify the retention period by appending a date or a period as specified by the date(4) command. Possible examples are `'+1 week'`, `'next month'` or `'42 days'`. Call the script with `-h` for a complete list of options.
- `usr/bin/purge-expired-amis.sh`: This script deregisters all your expired AMIs and the associated snapshots. Call the script with `-h` for a complete list of options.

## Feature requests ##
You're welcome to request more features regarding these scripts, though I may not implement all of them as I develop and maintain these scripts on my spare time. You are also invited to issue a pull request with a meaningful description of your changes.

#### Resources ####
1. AWS CLI: http://aws.amazon.com/cli/
2. JQ homepage: http://stedolan.github.io/jq/
3. Creating an IAM user: http://docs.aws.amazon.com/IAM/latest/UserGuide/Using_SettingUpUser.html
4. Manpage for date: http://linux.die.net/man/1/date
