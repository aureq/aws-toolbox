aws-toolbox/ec2/eni/multi-eni-routing
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
The files included in this folder and its subfolders are here to assist your Linux EC2 instance deal with multiple Elastic Network Interfaces (ENIs) and common routing issues.

For this script to work you need the following
* 2 or more ENIs attached to your EC2 instance.
* At least 1 local IP configured per interface.
* Your Security Group(s) configured to allow incomming traffic.

## Use cases ##

# You have an EC2 instance with 2 or more ENIs with 2 or more EIPs and you want your services publicly available.
# You have an EC2 instance with 2 or more ENIs with 2 or more local IP and you want your services available on all IP addresses.

## Notes ##
This script is not compatible with any other existing software firewall (like `iptables`). As this script is mainly attended for AWS users, you should use the Security Groups and the Network ACLs to control your network rather than using a software based firewall. By offloading the network filtering to your Security Groups, you will make your instance more responsive (and simpler to manage).

## Requirements ##
The scripts require very few things to work.
* IP Route 2 (networking and traffic control tools)
 * (`apt-get`|`yum`) `install iproute2`
* IP Tables (administration tools for packet filtering and NAT)
 * (`apt-get`|`yum`) `install iptables`
* IP Calc (parameter calculator for IPv4 addresses)
 * (`apt-get`|`yum`) `install ipcalc`

## Installation ##
You can deploy the scripts using the installation script `install.sh`. 

## Configuration ##
This script does not require any configuration as long as you have 2 or more ENIs and at least 1 local IP address on each interface

## Scripts ##
- `usr/bin/multi-eni-routing.sh`: Apply or flush (`-f`) the required rules to allow work with multiple ENIs and multiple IPs.
- `/etc/init.d/multi-eni-routing`: Startup control script.

## Feature requests ##
You're welcome to request more features regarding these scripts, though I may not implement all of them as I develop and maintain these scripts on my spare time. You are also invited to issue a pull request with a meaningful description of your changes.

## Acknowledgement ##
Thanks to Clyde for suggesting me this tool.

#### Resources ####
1. IPTables tutorial: https://www.frozentux.net/documents/iptables-tutorial/
2. Multi Link routing: http://lartc.org/howto/lartc.rpdb.multiple-links.html
3. Available IP per ENI: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#AvailableIpPerENI
