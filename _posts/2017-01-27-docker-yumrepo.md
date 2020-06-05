---
layout: post
title:  "Using Docker to create an ad hoc Yum repository"
date:   2017-01-27 19:45:00
comments: true
tags: docker yum
redirect_to: https://bacchi.org/posts/docker-yumrepo/
---

Docker can be used to quickly create and serve many services, one such example
is serving RPMs via Yum in an ad hoc manner.  Have you ever wanted to create a Yum
repository consisting of some RPMs very quickly to be used for testing
purposes?  I did this week.  I could have created the repo and installed a web
server on any machine.  But what if we had the RPMs and the Yum repository
both dynamically hosted on the servers where the Chef cookbooks were being
executed?  That was my goal for the
[docker-yumrepo](https://github.com/mbacchi/docker-yumrepo) project, enabling
the creation of an ad hoc Yum repository.

This tool has prerequisites that createrepo_c and docker to be installed prior.
You will place the RPMs you want in the repo in the src directory(after running
'make src'), then it will build and runs a docker image.  This will serve the
repository on port 80 (so make sure you don't have another webserver on
port 80.)  Voila, you now have a yum repository accessible on the URL:

```
http://localhost/docker-yumrepo
```

To use this you can install a Yum repo config file such as:

{% highlight shell %}
[user@centos docker-yumrepo]$ cat /etc/yum.repos.d/docker-yumrepo.repo
[docker-yumrepo]
name=docker-yumrepo
baseurl=http://localhost/docker-yumrepo
enabled=1
gpgcheck=0
{% endhighlight %}

Instructions are also available in the [README](https://github.com/mbacchi/docker-yumrepo/blob/master/README.md).

Enjoy!
