---
layout: post
title:  "Ajax/jQuery on AWS Lambda"
date:   2017-12-03 20:15:00
comments: true
published: true
tags: aws lambda ajax jquery
---

I've been trying to learn more about AWS Lambda, at the same time learning some
web development. For a newcomer to web application development, there is the
question of whether you work on leveling up with traditional server based apps
or "serverless", aka FaaS, aka Lambda. I wanted to try converting a simple Flask
app to Lambda, this is how I did it.

<!--more-->
##### What project should I work on?

Borrowing inspiration from Katelyn Lemay's
[tweet](https://twitter.com/klemay/status/937041036647550977) I started with a
straightforward application challenge from freeCodeCamp which displays quotes
when the user clicks a button. I figured this would exercise the muscles
required to do some client side scripting to experiment with how that worked on
Lambda. I also wanted to use Python vs. straight Javascript for the backend. I
found out that there are some interesting differences between running a Flask
application on a webserver vs. running it as a function on Lambda.

Here's the basic application I created (again, the idea and some css borrowed
from [@klemay](https://twitter.com/klemay/)):
[https://github.com/mbacchi/flask-quotes](https://github.com/mbacchi/flask-quotes)

I'm using [Zappa](https://github.com/Miserlou/Zappa) to deploy the Python app to
AWS Lambda. Zappa makes it easy to upload an app without having to do a lot of
preparation on AWS and packaging the bits manually. This is probably not useful
to everyone but I wanted to avoid the overhead of running Lambda in order to get
the app functioning before I learned it in detail, and Zappa helped with that.

##### What's so interesting about that?

This rudimentary application introduces two things to me. First I haven't done
Ajax/jQuery in a Python application before. That's not exciting to many folks
but when the concept is new to you its hard to work out the mechanics of the
process. Second I knew the term [Document Object
Model](https://www.w3schools.com/js/js_htmldom.asp) but didn't know how to
manipulate it nor how to initiate the Ajax call.

jQuery is intimidating too, but approachable if you start with the fundamentals.
Now I know $.getJSON() means roughly the same thing as $.ajax() (give or take,
its shorthand for the [ajax](http://api.jquery.com/jquery.getjson/) call.) But
wow is it confusing, for example what are the mechanics of not providing the
optional second parameter
([data](http://api.jquery.com/jquery.getjson/#jQuery-getJSON-url-data-success)),
yet allowing the third optional handler (success) to work? I use that [here](https://github.com/mbacchi/flask-quotes/blob/master/static/js/quote.js#L4).

##### Local webserver vs. Lambda

So after getting this to work using a local Flask server, how do we transition
to serving it from AWS? I initially tried to just upload the same app with Zappa
to Lambda, but while the inital load of the page worked, any time I clicked the
"New Quote" button nothing happened. This had me furiously searching google for whether or
not I needed a full REST API to work on AWS Lambda or some other changes. I did
find out I probably needed to enable CORS on the API Gateway.

There were other potential answers for why it wasn't working that I found out
about. Did I need to use
[lambda.invoke](http://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/browser-invoke-lambda-function-example.html)
or some similar mechanism to call the [new_quote](https://github.com/mbacchi/flask-quotes/blob/master/static/js/quote.js) function via the onClick action in the browser? Did I need to setup a full [REST API with Cognito](https://github.com/awslabs/aws-serverless-workshops/tree/master/WebApplication/4_RESTfulAPIs), or some other [API Gateway](https://stackoverflow.com/a/32058145/4332397) configuration that I was missing?

In the end I realized I was calling the new_quote function using a relative
path, but I needed to call the full URL to the API Gateway that I already knew
from performing "zappa deploy dev" earlier, so when I ran "zappa update" it used
the same gateway. That change looked like:

{% highlight diff %}
(venv) [user1@hostname flask-quotes]$ git diff 3d9eccd static/js/quote.js
diff --git a/static/js/quote.js b/static/js/quote.js
index aa51353..5df7a88 100644
--- a/static/js/quote.js
+++ b/static/js/quote.js
@@ -1,6 +1,6 @@
 function newQuote() {
     $(document).ready(function() {
-        $.getJSON('/new_quote',
+        $.getJSON('https://qlyaou0kc3.execute-api.us-east-1.amazonaws.com/dev/new_quote',
             function (data) {
                 $("#quote-text").text(data);
             });
(venv) [user1@hostname flask-quotes]$
{% endhighlight %}

For reference the Zappa settings for the project were:

{% highlight shell %}
(venv) [user1@hostname flask-quotes]$ cat zappa_settings.json
{
    "dev": {
        "app_function": "app.app",
        "aws_region": "us-east-1",
        "profile_name": "default",
        "project_name": "flask-quotes",
        "runtime": "python3.6",
        "s3_bucket": "zappa-p1kcu59iy",
	"cors": true
    }
}
{% endhighlight %}

Overall this was a fun challenge and although I banged my head on a few things I
learned a ton about Lambda, Javascript, Ajax, jQuery, client side scripting and
Zappa.
