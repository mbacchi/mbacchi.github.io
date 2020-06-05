---
layout: post
title:  "Using AWS Lambda@Edge on Cloudfront"
date:   2020-01-28 21:00:00
comments: true
published: true
tags: aws terraform cdn cloudfront lambda [aws cloudfront] [aws lambda]
redirect_to: https://bacchi.org/posts/lambda-edge-cloudfront/
---

I've been attempting to learn more about Lambda@Edge and how to use functions at
the AWS edge locations, so I wrote up this demo. It isn't performing a very
realistic operation, but it did allow me to understand the Lambda@Edge and
Cloudfront cache relationship (aka "event model") and how to intercept CDN cache
requests and modify responses in a Lambda function.

<!--more-->

### Demo Repository

The repository is at [https://github.com/mbacchi/lambda-edge-cloudfront-terraform](https://github.com/mbacchi/lambda-edge-cloudfront-terraform).

All the instructions for deploying the Terraform and uploading the html/js files
to the S3 bucket are in the
[README.md](https://github.com/mbacchi/lambda-edge-cloudfront-terraform/blob/master/README.md).
Follow those instructions to deploy using Terraform.

**NOTE**: Deploying can take 5 minutes in order to replicate the CloudFront
distribution to all AWS edge locations.

### Overview

The below steps are possible only after deploying all the AWS resources via
Terraform and placing the html/js files in the S3 bucket.

The basic flow of the actions in this demo are:

1. The CloudFront distribution sits in front of an S3 bucket which hosts the
   `index.html` page
2. When the Submit butten is pressed, the `index.html` page passes the
   querystring to the CloudFront distribution
3. The `viewer_request.py` Lambda function associated with the CloudFront
   distribution intercepts the request before the cache performs the lookup. In
   the function we perform a 302 redirect to the 2nd html page `other.html`,
   with the same query string as passed by the `index.html` page.
4. As the response is sent to the viewer, the `origin_response.py` Lambda
   function adds the `content-security-policy` that allows the `other.py` page
   to execute scripts in the CloudFront distribution domain, and allows
   github.com to be used to connect via an API call (also known as the connect
   source), all on the fly by adding HTTP headers to the response.
5. When loaded on the viewer's web browser, the `other.html` page makes the API
   call in `script.js` with the query string, and the async await function loads
   the response into the DOM when the API query returns.

### Lambda@Edge Basics

The below diagram (from [the AWS
documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-cloudfront-trigger-events.html))
explains how the request from and response to the viewer can be modified before
or after the cache.

![cloudfront lambda edge model]({{ site.baseurl }}/img/cloudfront-events-that-trigger-lambda-functions.png){: .center-image }{:height="900px" width="500px"}

In our example we will use the viewer request and origin response points of this
diagram to execute our Lambda functions and modify the request/response.

### Request and Response

The [viewer_request.py Lambda
function](https://github.com/mbacchi/lambda-edge-cloudfront-terraform/blob/master/lambda/viewer_request.py)
first looks at the request and identifies if the referrer URI includes the string
`index.html`. If so it redirects to the CloudFront distribution domain name,
appending the query string passed to the page.

As that redirect is handled it goes to the cache (and possibly to the origin) to
get the 2nd html page, and in the
[origin_response.py](https://github.com/mbacchi/lambda-edge-cloudfront-terraform/blob/master/lambda/origin_response.py)
the Content Security Policy (i.e. CSP) is dynamically configured to allow the
CloudFront distribution domain name to execute scripts(`script-src`).

Finally when the
[other.html](https://github.com/mbacchi/lambda-edge-cloudfront-terraform/blob/master/other.html)
page loads, it calls the Javascript async function to query the GitHub API with
the querystring username provided to `index.html`, and fills in the DOM with the
response json.

### Logging and troubleshooting

The output of the Lambda@Edge function (we have multiple print statements) is
directed to AWS Cloudwatch just like any Lambda function. This allows us to take
a look at the output and either debug or use for general information. This is
going to be in the region that is closest to your user making the request, so in
my case I am in Colorado, and the edge location apparently is `us-west-2`
(Oregon).

You can also use the Chrome (or Brave) developer console to show errors when
making requests. Hit `Ctrl-Shift-I` or use the browser menu to open the
Developer Tools and watch while you load the page.

This is all described in the
[README.md](https://github.com/mbacchi/lambda-edge-cloudfront-terraform/blob/master/README.md).

### Additional Resources

More help about CloudFront, Lambda@Edge and AWS can be found at these links:

* [Using AWS Lambda with CloudFront
  Lambda@Edge](https://docs.aws.amazon.com/lambda/latest/dg/lambda-edge.html)
* [Customizing Content at the Edge with
  Lambda@Edge](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-at-the-edge.html)
* [Tutorial: Creating a Simple Lambda@Edge
  Function](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-edge-how-it-works-tutorial.html)
* [CloudFront Events That Can Trigger a Lambda
  Function](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-cloudfront-trigger-events.html)

### Conclusion

This was an interesting project to work on. CloudFront and Lambda@Edge appear
quite useful now that I've learned the basics. Hope you got something out of
this demo too.

Enjoy!

### Addendum

In the original version of this post, I indicated that these deployments could
take anywhere from 20-30 minutes. I've corrected this information because that
has now changed.

The AWS CloudFront team has recently shared [updated information about their
deployment
times](https://aws.amazon.com/blogs/networking-and-content-delivery/slashing-cloudfront-change-propagation-times-in-2020-recent-changes-and-looking-forward/).
They have improved these deployments from 20-30 minutes to typically around 5
minutes.

This is a major improvement and makes it much easier to use.
