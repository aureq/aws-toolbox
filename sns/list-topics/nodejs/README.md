aws-toolbox/sns/list-topics/nodejs
=========

## Audience ##
This documentation and the associated scripts are intended for software developers that are using NodeJS and the Javascript SDK for AWS.

## License ##
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

## Description ##
The code included in ```list-topics.js``` allows a developer to retrieve all topics in a given region. The code is designed so that all topics are returned at once, even if ```NextToken``` was required.

This code is designed to help developers to avoid the common *callback hell* due to code recursivity. It should be fairly easy to reuse the same code on other API calls that require ```NextToken```.

## Requirements ##
The script require very few things to work.
* NodeJS
 * ```apt-get install nodejs```
* The AWS SDK for NodeJS(1)
 * `npm install aws-sdk`
* The ```bluebird```(2) package to implement the *promis*e
 * `npm install bluebird`

## Configuration ##
For the script to work, you need to enter your ```accessKey```, ```secretAccessKey``` and ```region```.
Please ensure that your IAM user has sufficient permissions to perform the operation.

## Resources ##
1. AWS SDK for JavaScript in Node.js: http://aws.amazon.com/sdk-for-node-js/
2. bluebird package for NodeJS: https://www.npmjs.com/package/bluebird
