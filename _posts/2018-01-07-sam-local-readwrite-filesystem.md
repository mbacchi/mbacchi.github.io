---
layout: post
title: "Writing to the AWS Lambda SAM Local container /tmp filesystem"
date: 2018-01-07 14:10:00
comments: true
published: true
tags: lambda sam local
---

While using [AWS Lambda SAM
Local](https://docs.aws.amazon.com/lambda/latest/dg/test-sam-local.html) to test
Lambda functions locally, I encountered an error writing to the current
directory where the function was running in the container (/var/task/). I'm not
claiming a best practice of writing to the filesystem while running a Lambda
function, but that's part of my learning process for the moment, and I will
investigate other workflows shortly. But what I was able to get working
successfuly was writing to the /tmp filesystem instead of the current working
directory.

Here is the example code where it writes to the current directory with an the
result that we encounter the error that the directory is read only:

<!--more-->

{% highlight shell %}
[mbacchi@nuc2 sample-sam-local-write]$ cat samlocalwrite.py
import os
import sys


def handler(event, context):
    print("Starting samlocalwrite lambda handler function")
    print("Directory provided from event was: {}".format(event['directory']))

    remote_repo = event['directory']

    #local_repo = os.path.join(os.path.sep, "tmp", os.path.basename(event['directory']))
    local_repo = os.path.basename(event['directory'])

    if not os.path.exists(local_repo):
        os.makedirs(local_repo)

    with open(local_repo + "blah.txt", 'w') as f:
        f.write('blah\n')

    return "Hello"
{% endhighlight %}

And the output of the `sam local invoke` command:

{% highlight shell %}
[mbacchi@nuc2 sample-sam-local-write]$ sam local invoke "SamLocalWriteFunction" -e event.json
2018/01/07 15:50:24 Successfully parsed template.yaml
2018/01/07 15:50:24 Connected to Docker 1.35
2018/01/07 15:50:24 Fetching lambci/lambda:python3.6 image for python3.6 runtime...
python3.6: Pulling from lambci/lambda
f338a32fa56c: Pull complete
4926b20b634f: Pull complete
298eae5902d7: Pull complete
e58d162628c7: Pull complete
e02bc73f2e71: Pull complete
Digest: sha256:0682e157b34e18cf182b2aaffb501971c7a0c08c785f337629122b7de34e3945
Status: Downloaded newer image for lambci/lambda:python3.6
2018/01/07 15:51:25 Invoking samlocalwrite.handler (python3.6)
2018/01/07 15:51:25 Decompressing /home/mbacchi/data/repos/mbacchi/sample-sam-local-write/samlocalwrite.zip
2018/01/07 15:51:46 WARNING: No AWS credentials found. Missing credentials may lead to slow startup times as detailed in https://github.com/awslabs/aws-sam-local/issues/134
2018/01/07 15:51:46 Mounting /tmp/aws-sam-local-1515358285999917851 as /var/task:ro inside runtime container
START RequestId: 9371dabf-9678-4fc4-83d8-5d8c8cf8c9fa Version: $LATEST
Starting samlocalwrite lambda handler function
Directory provided from event was: whatever
[Errno 30] Read-only file system: 'whatever': OSError
Traceback (most recent call last):
  File "/var/task/samlocalwrite.py", line 18, in handler
    os.makedirs(local_repo)
  File "/var/lang/lib/python3.6/os.py", line 220, in makedirs
    mkdir(name, mode)
OSError: [Errno 30] Read-only file system: 'whatever'

END RequestId: 9371dabf-9678-4fc4-83d8-5d8c8cf8c9fa
REPORT RequestId: 9371dabf-9678-4fc4-83d8-5d8c8cf8c9fa Duration: 161 ms Billed Duration: 0 ms Memory Size: 0 MB Max Memory Used: 18 MB

{"errorMessage": "[Errno 30] Read-only file system: 'whatever'", "errorType": "OSError", "stackTrace": [["/var/task/samlocalwrite.py", 18, "handler", "os.makedirs(local_repo)"], ["/var/lang/lib/python3.6/os.py", 220, "makedirs", "mkdir(name, mode)"]]}

{% endhighlight %}

If we make a slight modification to write to the `/tmp` filesystem:

{% highlight shell %}
[mbacchi@nuc2 sample-sam-local-write]$ diff samlocalwrite.py samlocalwrite-new.py
14,15c14,15
<     #local_repo = os.path.join(os.path.sep, "tmp", os.path.basename(event['directory']))
<     local_repo = os.path.basename(event['directory'])
---
>     local_repo = os.path.join(os.path.sep, "tmp", os.path.basename(event['directory']))
>     #local_repo = os.path.basename(event['directory'])
{% endhighlight %}

We get a successful run:

{% highlight shell %}
[mbacchi@nuc2 sample-sam-local-write]$ sam local invoke "SamLocalWriteFunction" -e event.json
2018/01/07 15:55:54 Successfully parsed template.yaml
2018/01/07 15:55:54 Connected to Docker 1.35
2018/01/07 15:55:54 Fetching lambci/lambda:python3.6 image for python3.6 runtime...
python3.6: Pulling from lambci/lambda
Digest: sha256:0682e157b34e18cf182b2aaffb501971c7a0c08c785f337629122b7de34e3945
Status: Image is up to date for lambci/lambda:python3.6
2018/01/07 15:55:54 Invoking samlocalwrite.handler (python3.6)
2018/01/07 15:55:54 Decompressing /home/mbacchi/data/repos/mbacchi/sample-sam-local-write/samlocalwrite.zip
2018/01/07 15:56:15 WARNING: No AWS credentials found. Missing credentials may lead to slow startup times as detailed in https://github.com/awslabs/aws-sam-local/issues/134
2018/01/07 15:56:15 Mounting /tmp/aws-sam-local-1515358554848977835 as /var/task:ro inside runtime container
START RequestId: 0af0a302-49db-4ca2-a0fa-db31acb0182a Version: $LATEST
Starting samlocalwrite lambda handler function
Directory provided from event was: whatever
END RequestId: 0af0a302-49db-4ca2-a0fa-db31acb0182a
REPORT RequestId: 0af0a302-49db-4ca2-a0fa-db31acb0182a Duration: 160 ms Billed Duration: 0 ms Memory Size: 0 MB Max Memory Used: 18 MB

"Hello"
{% endhighlight %}

Again, this may not be the perfect solution but it is a way to write to the
image filesystem if necessary in your Lambda function.
