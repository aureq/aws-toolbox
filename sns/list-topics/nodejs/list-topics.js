// this code demonstrate how to get all your topics
// and trigger a call back once all the results have been fetched
// this is useful when you need to deal with my than 100 results
// at a time
//
// you need to install 'bluebird' and 'aws-sdk'
// npm install aws-sdk
// npm install bluebird
// export NODE_PATH=./:node_modules/aws-sdk/:node_modules/bluebird/

var Promise = require('bluebird'),
    AWS = require('aws-sdk'),
    sns = new AWS.SNS(
        {
            apiVersion: '2010-03-31',
            accessKeyId: 'AKIA_FIXME',
            secretAccessKey: 'FIXME',
            region: 'ap-southeast-2',
            sslEnabled: true
        }
    );

Promise.promisifyAll(Object.getPrototypeOf(sns));

var promiseWhile = function (condition, action) {
    "use strict";
    var resolver = Promise.defer(),
        loop = function () {
            if (!condition()) {
                return resolver.resolve();
            }
            return Promise.cast(action())
                .then(loop)
                .catch(resolver.reject);
        };
    process.nextTick(loop);
    return resolver.promise;
};


var token = '',
    params = {},
    topics = [];

promiseWhile(function () {
    "use strict";
    return token !== null;
}, function () {
    "use strict";
    params.NextToken = token;
    return new Promise(function (resolve, reject) {
        sns.listTopics(params, function (err, data) {
            if (err) {
                console.log("Reject");
                reject(err);
            } else {
                console.log("Accept");
                resolve(data);
            }});
    }).then(function (values) {
        console.log("Got " + values.Topics.length + " topics");
        topics = topics.concat(values.Topics);
        console.log("we have " + topics.length + " topics");
        if (values.NextToken) {
            token = values.NextToken;
        } else {
            token = null;
        }
    });
}).then(function () {
    console.log(topics);
    console.log("In all, we collected " + topics.length + " topics");
});

