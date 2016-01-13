aws-toolbox/ses/sending-email-example/php
=========

## Audience ##
This documentation and the associated scripts are intended for system administrator and Developers that are using Amazon Simple Email Service (SES).

## License ##
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

## Description ##
The files included in this folder and its subfolders are here to help you send HTML/TEXT email messages using Amazon Simple Email Service (SES) using the SMTP protocol.

## Requirements ##
The script requires very few things to work.
* PHP for the command line
 * `apt-get install php5-cli`
* PHPMailer(1)
 * From the cloned repository, run the commands below
 * `git submodule init`
 * `git submodule update`
* A valid SMTP credentials as generated using the SES Management Console
 * Log-in to the AWS Management console
 * Select the SES Service (any region)
 * On the left hand side, select `SMTP Settings`
 * Click on `Create My SMTP Credentials`
 * Follow the SMTP Credential Wizard up until the end

## Installation ##
There's no required installation procedure.

## Configuration ##
There's no required

## Scripts ##
- `ses-sample-email`: This is the main script to used to connect to one of the 3 SMTP endpoints for Amazon SES to send your message out. Please note that for security and privacy reasons, **all communications** use either **TLS** or **SSL**.

## Feature requests ##
You're welcome to request more features regarding these scripts, though I may not implement all of them as I develop and maintain these scripts on my spare time. You are also invited to issue a pull request with a meaningful description of your changes.

## Acknowledgement ##
Thanks to James who had a need for this tool.
Thanks to Russell who needed an example of a SES cross-acount message

#### Resources ####
1. PHPMailer: https://github.com/PHPMailer/PHPMailer
