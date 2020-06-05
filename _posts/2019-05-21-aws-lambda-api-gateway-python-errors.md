---
layout: post
title: "Returning HTTP Errors from API Gateway in AWS Lambda Functions using Python and Serverless Framework"
date: 2019-05-21 12:00:00
comments: true
published: true
tags: api [Serverless Framework] serverless lambda python
redirect_to: https://bacchi.org/posts/aws-lambda-api-gateway-python-errors/
---


There are many examples available for how to return an error from an AWS Lambda
function through API Gateway to a client in Node.js, but relatively few for how
to do so using the Python runtime. Here we will try to give some basic info
using Python with a POST action.

#### Prereqs

This assumes you already have an AWS account, have configured your AWS access
credentials or profile and set the AWS_REGION environment variable to your
region of choice. Otherwise it will use the `us-west-2` region by default.

You will also need the [Serverless Framework](serverless.com) to be installed.

#### Lambda-Proxy Integration

In this blog post we are going to cover the [Lambda-Proxy integration
method](https://serverless.com/framework/docs/providers/aws/events/apigateway/#lambda-proxy-integration)
versus the [Lambda
method](https://serverless.com/framework/docs/providers/aws/events/apigateway/#lambda-integration).
This is the simplest and from what I've found least documented because it just
seems obvious to AWS technical writers, Serverless framework developers and blog
authors. Most examples are written in Node.js because of that because that's
what both AWS and Serverless framework documents discuss. Our example hopes to
make it a little more clear.

#### Create Serverless project

Let's start by creating a new Serverless framework project. We will be using the
`aws-python3` template for this, which populates a basic `serverless.yml`
configuration file and a basic handler function. To do so we use the `serverless
create` command (abbreviated as `sls create` for brevity) to generate the skeleton to
our project.

{% highlight shell %}
[user@linux serverless]$ sls create --template aws-python3 --path test-lambda-exception-handling
Serverless: Generating boilerplate...
Serverless: Generating boilerplate in "/serverless/test-lambda-exception-handling"
 _______                             __
|   _   .-----.----.--.--.-----.----|  .-----.-----.-----.
|   |___|  -__|   _|  |  |  -__|   _|  |  -__|__ --|__ --|
|____   |_____|__|  \___/|_____|__| |__|_____|_____|_____|
|   |   |             The Serverless Application Framework
|       |                           serverless.com, v1.38.0
 -------'

Serverless: Successfully generated boilerplate for template: "aws-python3"
{% endhighlight %}

Once we have this template in place, you can modify the files yourself, or copy
the below into your project. It is also available in [my GitHub
repository](https://github.com/mbacchi/python-lambda-exception-handling) if you'd
rather look at that.

The handler function and YAML are:

<figure>
  <figcaption>handler.py</figcaption>
{% highlight python %}
import json

def throw_error(event, context):
    data = json.loads(event['body'])
    print(data) # this can be seen in CloudWatch Logs

    response = {
        "statusCode": 400,
        "headers": {
            "Content-Type": 'application/json',
            "context.aws_request_id": context.aws_request_id # for fun show the Lambda requestID
        },
        "body": "Bad Request",
        "isBase64Encoded": False
    }

    return response
{% endhighlight %}
</figure>

<figure>
  <figcaption>serverless.yaml</figcaption>
{% highlight yaml %}
service: test-lambda-exception-handling

provider:
  name: aws
  runtime: python3.7
  region: ${AWS_REGION, 'us-east-2'}

  stage: dev

functions:
  throw_error:
    handler: handler.throw_error
    events:
      - http:
          path: throw
          method: post
          cors: true
{% endhighlight %}
</figure>


#### What this does

The `serverless.yml` file defines the FaaS or Cloud provider where you are going
to run the function, as well as the function itself. This is a very basic single
function for the purposes of this demo. The documentation is
[here](https://serverless.com/framework/docs/providers/aws/). As you can see we
are running in AWS Lambda, and using the function named `throw_error`.

The handler can be named anything, but must be referenced in the `.yml` file.
We're using the name that the Serverless template provided for us. In a Lambda
runtime environment, you're passed an event object and a context object. You are
provided event details including any data passed to the function via the POST
request. The context object has information about the execution environment,
invocation and other things, [described
here](https://docs.aws.amazon.com/lambda/latest/dg/python-context-object.html).

Our handler simply loads the event data, and then prints it so that it can be
viewed in Cloudwatch Logs. This isn't returned to the calling client. Because
we're using API Gateway, the response must conform to a [specific
format](https://docs.aws.amazon.com/apigateway/latest/developerguide/handle-errors-in-lambda-integration.html).

In our function we simply return a `400 Bad Request` response immediately after
decoding the data passed in.

#### Deploying the project

If we're cautios we can look at what will be deployed by first running the `sls
package` command. Then we can look in the `.zip` file that it will upload to AWS
Lambda.

{% highlight shell %}
[user@linux test-lambda-exception-handling]$ sls package
Serverless: Packaging service...
Serverless: Excluding development dependencies...
[user@linux test-lambda-exception-handling]$ ls -a
.  ..  .gitignore  handler.py  .serverless  serverless.yml
[user@linux test-lambda-exception-handling]$ ls .serverless/
cloudformation-template-create-stack.json  cloudformation-template-update-stack.json  serverless-state.json  test-lambda-exception-handling.zip
[user@linux test-lambda-exception-handling]$ zipinfo -l .serverless/test-lambda-exception-handling.zip 
Archive:  .serverless/test-lambda-exception-handling.zip
Zip file size: 407 bytes, number of entries: 1
-rw-rw-r--  4.5 unx      451 bl      273 defN 80-Jan-01 00:00 handler.py
1 file, 451 bytes uncompressed, 273 bytes compressed:  39.5%
{% endhighlight %}


To deploy we use the `sls deploy` command.

{% highlight shell %}
[user@linux test-lambda-exception-handling]$ sls deploy
Serverless: Packaging service...
Serverless: Excluding development dependencies...
Serverless: Creating Stack...
Serverless: Checking Stack create progress...
.....
Serverless: Stack create finished...
Serverless: Uploading CloudFormation file to S3...
Serverless: Uploading artifacts...
Serverless: Uploading service test-lambda-exception-handling.zip file to S3 (407 B)...
Serverless: Validating template...
Serverless: Updating Stack...
Serverless: Checking Stack update progress...
.................................
Serverless: Stack update finished...
Service Information
service: test-lambda-exception-handling
stage: dev
region: us-east-2
stack: test-lambda-exception-handling-dev
resources: 11
api keys:
  None
endpoints:
  POST - https://7vt4w7lb4l.execute-api.us-east-2.amazonaws.com/dev/throw
functions:
  throw_error: test-lambda-exception-handling-dev-throw_error
layers:
  None
{% endhighlight %}

This returns the URL for POST actions, which we will use in our next step.

#### Invoking the Function

Now we can simply run a POST against our new function URL and see how it will
respond.

{% highlight shell %}
[user@linux test-lambda-exception-handling]$ curl -i -X POST https://7vt4w7lb4l.execute-api.us-east-2.amazonaws.com/dev/throw --data '{"blah": "blah1"}'
HTTP/2 400 
content-type: application/json
content-length: 11
date: Wed, 22 May 2019 01:34:50 GMT
x-amzn-requestid: ca8164e7-7c31-11e9-b114-d91ebd2032b3
context.aws_request_id: 87f10bcd-7c85-46d5-bcd7-493aca45e1f0
x-amz-apigw-id: aD8RIG3MCYcFk2w=
x-amzn-trace-id: Root=1-5ce4a73a-af05ec85fe34062d036b396f;Sampled=0
x-cache: Error from cloudfront
via: 1.1 c4fb40b7909e4dd897bba2e297b284e7.cloudfront.net (CloudFront)
x-amz-cf-id: Sovagss83OsF-hv8b7QHcf9GkmV2r1A_XEF8KzI18GMrhWzGvfaGSQ==

Bad Request[user@linux test-lambda-exception-handling]$ 
{% endhighlight %}

This shows that we receive the `Bad Request` response, with HTTP status code 400
as expected.

In a future post I'll describe how to return errors in Python with the [Lambda
integration](https://serverless.com/framework/docs/providers/aws/events/apigateway/#lambda-integration)
method.
