---
layout: post
title: "Why Did Official Python Docker Images Disappear for an Afternoon?"
date: 2019-07-29 12:00:00
comments: true
published: true
tags: python docker debian buster alpine dockerhub
---

We have all become accustomed to services on the internet being reliable and
available approximately 100% of the time. Many services obviously have outages,
recently GitHub, Cloudflare, Twitter, Facebook have all had widespread service
disruptions. Some apps affect downstream processes and services that rely on
them. This is a story about how I found the official Python images on Docker Hub
were missing for the `linux/amd64` architecture for an entire
afternoon(potentially longer).

# The Stage is Set

Unfortunately, the [official Python Docker Hub](https://hub.docker.com/_/python)
images don't explicitly indicate which architecture they support. You would
expect images for popular distributions such as Debian Buster would be available
for both amd64 and ARM architectures.

On Saturday, July 13 I was working on some Dockerfiles that I use to test my
[Python library](https://github.com/mbacchi/python-git-secrets), and I couldn't
download the Buster image I had used in the past. The error I encountered was:

```
no matching manifest for linux/amd64 in the manifest list entries
```

This [support
page](https://success.docker.com/article/error-pulling-image-no-matching-manifest)
indicated I could list all images for my architecture using a command similar
to:

```
DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect -v python:3.8-rc-buster | jq '.[].Descriptor.platform'
{
  "architecture": "amd64",
  "os": "linux"
}
{
  "architecture": "arm",
  "os": "linux",
  "variant": "v6"
}
...
```

The only architecure returned for this image at the time was ARM. I worked
around this problem by [using the Alpine Linux
image](https://github.com/mbacchi/dockerfiles/tree/master/python3) instead
because I needed to get this testing completed. But that limitation struck me as
strange. It kept gnawing at me, I couldn't shake the feeling I must have been
using incorrect command. A couple weeks later I decided to write a blog post
about my experience. Funny enough as I was writing the very blog post you're
reading now, I found that the Buster images were in fact available once again.

# Act Two

Today the results returned from Docker Hub include amd64, ARM and others:

```
DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect -v python:3.8-rc-buster | jq '.[].Descriptor.platform'
{
  "architecture": "amd64",
  "os": "linux"
}
{
  "architecture": "arm",
  "os": "linux",
  "variant": "v5"
}
{
  "architecture": "arm",
  "os": "linux",
  "variant": "v7"
}
{
  "architecture": "arm64",
  "os": "linux",
  "variant": "v8"
}
{
  "architecture": "386",
  "os": "linux"
}
{
  "architecture": "ppc64le",
  "os": "linux"
}
{
  "architecture": "s390x",
  "os": "linux"
}
```

This is expected. But not what I found 2 weeks ago.

There was no outage reported on the [Docker Hub status
page](https://status.docker.com/pages/history/533c6539221ae15e3f000031) for that
day. It stands to reason then that the Python official Docker images were
somehow not built properly for amd64 and other platforms during this window of
time.

I would love to know how this occurred. I guess this reinforces how the folks
who say [everything is
broken](https://www.hanselman.com/blog/EverythingsBrokenAndNobodysUpset.aspx)
really have a point. At least I wasn't using this in an automated process as
part of a CI pipeline or something. Although I also see that type of transient
service outage in my day job an just hit the `Restart Job` button in Jenkins.
