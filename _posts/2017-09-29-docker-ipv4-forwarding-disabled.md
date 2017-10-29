---
layout: post
title:  "Docker error IPv4 forwarding is disabled"
date:   2017-09-29 10:15:00
comments: true
tags: docker
---

Another common error is that the docker daemon cannot connect to the outside
world to download anything during build time. This can be corrected in a number
of ways, but I have done it thusly.

The error is commonly encountered as you are trying to build a docker image, the
warning **"[Warning] IPv4 forwarding is disabled. Networking will not work."**
tells you that you need to enable IPv4 forwarding.

<!--more-->
{% highlight shell %}
Step 10 : RUN set -x && pip install -U pip setuptools && pip install -r /tmp/requirements/dev.txt ...
 ---> [Warning] IPv4 forwarding is disabled. Networking will not work.
 ---> Running in b4b9fb134518
+ pip install -U pip setuptools
Retrying (Retry(total=4, connect=None, read=None, redirect=None)) after connection
broken by NewConnectionError(Failed to establish a new connection: [Errno -2]
Name or service not known,): /simple/pip/
{% endhighlight %}

First setup the docker daemon config file to have a DNS server or two available
to make requests of:

{% highlight shell %}
[mbacchi@centos7 ~]$ cat /etc/docker/daemon.json
{
    "dns": ["10.1.1.254","8.8.8.8","10.115.1.220"],
    "live-restore": true
}
{% endhighlight %}

You can see above that I have multiple local(intranet vpn) nameservers as well
as the Google DNS server 8.8.8.8. This would require a docker daemon restart
to be enabled(systemctl restart docker), but we will wait for the next step to
be completed before performing that daemon restart.

Now we must enable forwarding between interfaces in the kernel. This will
be done using the sysctl parameter net.ipv4.ip_forward. It can be set once from
the command line but upon system restart will not be retained, so I set it in
the docker sysctl file:

{% highlight shell %}
[mbacchi@centos7 ~]$ cat  /usr/lib/sysctl.d/99-docker.conf
fs.may_detach_mounts=1
net.ipv4.ip_forward=1
{% endhighlight %}

This will then set the net.ipv4.ip_forward variable to true every time the docker
daemon is started or restarted.

Now we can perform that restart and make sure both of these changes are enabled.

{% highlight shell %}
[mbacchi@centos7 ~]$ sudo systemctl restart docker
[mbacchi@centos7 ~]$
{% endhighlight %}
