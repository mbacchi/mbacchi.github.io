---
layout: post
title:  "Using Zappa as an AWS Lambda Python Framework"
date:   2017-12-01 19:45:00
comments: true
published: true
tags: aws lambda zappa
---

I spent a little time with [Zappa](https://github.com/Miserlou/Zappa) today which is an AWS Lambda (aka "serverless")
framework for Python. Its not hard to create a very basic Flask application, then invoke Zappa to perform the many manual
steps of creating a Lambda function, resulting in a URL where your application is running.

First, I verified I was using Python 3.6, then I created a Python Virtual environment and installed Zappa and then Flask.

<!--more-->
{% highlight shell %}
[user1@hostname hello]$ python3 --version
Python 3.6.2
[user1@hostname hello]$ mkvenv
[user1@hostname hello]$
[user1@hostname hello]$ . venv/bin/activate
(venv) [user1@hostname hello]$ pip install zappa
Collecting zappa
  Using cached zappa-0.45.1-py3-none-any.whl
...
Collecting cfn_flip>=0.2.5 (from troposphere>=1.9.0->zappa)
  Using cached cfn_flip-0.2.5.tar.gz
Installing collected packages: PyYAML, six, python-dateutil, docutils, jmespath, botocore, s3transfer,
boto3, click, placebo, kappa, durationpy, wheel, wsgi-request-logger, toml, urllib3, chardet, certifi,
idna, requests, argcomplete, Unidecode, python-slugify, future, lambda-packages, tqdm, hjson, Werkzeug,
base58, cfn-flip, troposphere, zappa
  Running setup.py install for PyYAML ... done
  Running setup.py install for placebo ... done
  Running setup.py install for kappa ... done
  Running setup.py install for durationpy ... done
  Running setup.py install for wsgi-request-logger ... done
  Running setup.py install for toml ... done
  Running setup.py install for future ... done
  Running setup.py install for lambda-packages ... done
  Running setup.py install for hjson ... done
  Running setup.py install for cfn-flip ... done
  Running setup.py install for troposphere ... done
Successfully installed PyYAML-3.12 Unidecode-0.4.21 Werkzeug-0.12 argcomplete-1.9.2 base58-0.2.4 boto3-1.4.8
botocore-1.8.6 certifi-2017.11.5 cfn-flip-0.2.5 chardet-3.0.4 click-6.7 docutils-0.14 durationpy-0.5
future-0.16.0 hjson-3.0.1 idna-2.6 jmespath-0.9.3 kappa-0.6.0 lambda-packages-0.19.0 placebo-0.8.1
python-dateutil-2.6.1 python-slugify-1.2.4 requests-2.18.4 s3transfer-0.1.12 six-1.11.0 toml-0.9.3
tqdm-4.19.1 troposphere-2.1.1 urllib3-1.22 wheel-0.30.0 wsgi-request-logger-0.4.6 zappa-0.45.1

(venv) [user1@hostname hello]$ pip install Flask
Collecting Flask
  Using cached Flask-0.12.2-py2.py3-none-any.whl
Requirement already satisfied: click>=2.0 in ./venv/lib/python3.6/site-packages (from Flask)
Collecting itsdangerous>=0.21 (from Flask)
  Using cached itsdangerous-0.24.tar.gz
Collecting Jinja2>=2.4 (from Flask)
  Downloading Jinja2-2.10-py2.py3-none-any.whl (126kB)
    100% |████████████████████████████████| 133kB 2.6MB/s
Requirement already satisfied: Werkzeug>=0.7 in ./venv/lib/python3.6/site-packages (from Flask)
Collecting MarkupSafe>=0.23 (from Jinja2>=2.4->Flask)
  Using cached MarkupSafe-1.0.tar.gz
Building wheels for collected packages: itsdangerous, MarkupSafe
  Running setup.py bdist_wheel for itsdangerous ... done
  Stored in directory: /home/user1/.cache/pip/wheels/fc/a8/66/24d655233c757e178d45dea2de22a04c6d92766abfb741129a
  Running setup.py bdist_wheel for MarkupSafe ... done
  Stored in directory: /home/user1/.cache/pip/wheels/88/a7/30/e39a54a87bcbe25308fa3ca64e8ddc75d9b3e5afa21ee32d57
Successfully built itsdangerous MarkupSafe
Installing collected packages: itsdangerous, MarkupSafe, Jinja2, Flask
Successfully installed Flask-0.12.2 Jinja2-2.10 MarkupSafe-1.0 itsdangerous-0.24
{% endhighlight %}

I created a very simple Hello World app in Flask(borrowed from the Flask quickstart [here](http://flask.pocoo.org/docs/0.12/quickstart/)):

{% highlight shell %}
(venv) [user1@hostname hello]$ cat app.py
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, Lambda users!'
{% endhighlight %}

With the Flask "application" in my current directory, I was able to run "zappa init" to get everything built. It asks some questions:

{% highlight shell %}
(venv) [user1@hostname blod-dir]$ zappa init

███████╗ █████╗ ██████╗ ██████╗  █████╗
╚══███╔╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗
  ███╔╝ ███████║██████╔╝██████╔╝███████║
 ███╔╝  ██╔══██║██╔═══╝ ██╔═══╝ ██╔══██║
███████╗██║  ██║██║     ██║     ██║  ██║
╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝  ╚═╝

Welcome to Zappa!

Zappa is a system for running server-less Python web applications on AWS Lambda and AWS API Gateway.
This `init` command will help you create and configure your new Zappa deployment.
Let's get started!

Your Zappa configuration can support multiple production stages, like 'dev', 'staging', and 'production'.
What do you want to call this environment (default 'dev'):

AWS Lambda and API Gateway are only available in certain regions. Let's check to make sure you have a profile
set up in one that will work.
Okay, using profile default!

Your Zappa deployments will need to be uploaded to a private S3 bucket.
If you don't have a bucket yet, we'll create one for you too.
What do you want call your bucket? (default 'zappa-fysh7qlsu'):

It looks like this is a Flask application.
What's the modular path to your app's function?
This will likely be something like 'your_module.app'.
We discovered: app.app
Where is your app's function? (default 'app.app'):

You can optionally deploy to all available regions in order to provide fast global service.
If you are using Zappa for the first time, you probably don't want to do this!
Would you like to deploy this application globally? (default 'n') [y/n/(p)rimary]: n

Okay, here's your zappa_settings.json:

{
    "dev": {
        "app_function": "app.app",
        "aws_region": "us-east-1",
        "profile_name": "default",
        "project_name": "hello",
        "runtime": "python3.6",
        "s3_bucket": "zappa-fysh7qlsu"
    }
}

Does this look okay? (default 'y') [y/n]: y

Done! Now you can deploy your Zappa application by executing:

	$ zappa deploy dev

After that, you can update your application code with:

	$ zappa update dev

To learn more, check out our project page on GitHub here: https://github.com/Miserlou/Zappa
and stop by our Slack channel here: https://slack.zappa.io

Enjoy!,
 ~ Team Zappa!
{% endhighlight %}

Simple, right? After that I deployed the application:

{% highlight shell %}
(venv) [user1@hostname hello]$ zappa deploy dev

Calling deploy for stage dev..
Creating hello-dev-ZappaLambdaExecutionRole IAM Role..
Creating zappa-permissions policy on hello-dev-ZappaLambdaExecutionRole IAM Role.
Downloading and installing dependencies..
 - sqlite==python36: Using precompiled lambda package
Packaging project as zip.
Uploading hello-dev-1512173647.zip (5.7MiB)..
100%|██████████████████████████████████████████████████████████████████████████████████████████| 6.02M/6.02M [00:01<00:00, 3.63MB/s]
Scheduling..
Scheduled hello-dev-zappa-keep-warm-handler.keep_warm_callback with expression rate(4 minutes)!
Uploading hello-dev-template-1512173657.json (1.6KiB)..
100%|██████████████████████████████████████████████████████████████████████████████████████████| 1.59K/1.59K [00:00<00:00, 10.7KB/s]
Waiting for stack hello-dev to create (this can take a bit)..
100%|████████████████████████████████████████████████████████████████████████████████████████████████| 4/4 [00:15<00:00,  5.89s/res]
Deploying API Gateway..
Deployment complete!: https://te5p0mowh3.execute-api.us-east-1.amazonaws.com/dev
{% endhighlight %}

After uploading, you can use curl to connect:

{% highlight shell %}
(venv) [user1@hostname hello]$ curl https://te5p0mowh3.execute-api.us-east-1.amazonaws.com/dev
Hello, Lambda users!
{% endhighlight %}

And here's the AWS console showing the invocation count of the lambda function:

![lambda console]({{ site.baseurl }}/img/hello-dev.png){: .center-image }{:height="1000px" width="700px"}

To remove the test Lambda I created, use "zappa undeploy":

{% highlight shell %}
(venv) [user1@hostname hello]$ zappa undeploy dev
Calling undeploy for stage dev..
Are you sure you want to undeploy? [y/n] y
Deleting API Gateway..
Waiting for stack hello-dev to be deleted..
Unscheduling..
Unscheduled hello-dev-zappa-keep-warm-handler.keep_warm_callback.
Deleting Lambda function..
Done!
{% endhighlight %}
