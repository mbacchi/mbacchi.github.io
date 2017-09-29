---
layout: post
title:  "Docker socket group permissions"
date:   2017-09-28 15:15:00
comments: true
tags: docker
---

I always forget this when trying to run docker as a non-root user, so documenting
it for posterity.

If you get an error connecting to the docker daemon as a standard user, such as:
<!--more-->
{% highlight shell %}
[mbacchi@centos7 ~]$ docker ps
Cannot connect to the Docker daemon. Is the docker daemon running on this host?
{% endhighlight %}

And you're sure your docker daemon is actually up:

{% highlight shell %}
[mbacchi@centos7 ~]$ sudo systemctl status docker
● docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; disabled; vendor preset: disabled)
   Active: active (running) since Thu 2017-09-28 17:08:49 EDT; 8min ago
     Docs: http://docs.docker.com
 Main PID: 3375 (dockerd-current)
   CGroup: /system.slice/docker.service
           ├─3375 /usr/bin/dockerd-current --add-runtime docker-runc=/usr/libexec/docker/docker-runc-current --defaul...
           └─3380 /usr/bin/docker-containerd-current -l unix:///var/run/docker/libcontainerd/docker-containerd.sock -...

Sep 28 17:08:48 centos7 dockerd-current[3375]: time="2017-09-28T17:08:48.265161468-04:00" level=info msg="Graph ...onds"
Sep 28 17:08:48 centos7 dockerd-current[3375]: time="2017-09-28T17:08:48.265978330-04:00" level=warning msg="mou...ound"
Sep 28 17:08:48 centos7 dockerd-current[3375]: time="2017-09-28T17:08:48.266206907-04:00" level=info msg="Loadin...art."
Sep 28 17:08:48 centos7 dockerd-current[3375]: ......time="2017-09-28T17:08:48.473174045-04:00" level=info msg="...true"
Sep 28 17:08:48 centos7 dockerd-current[3375]: time="2017-09-28T17:08:48.840829045-04:00" level=info msg="Defaul...ress"
Sep 28 17:08:49 centos7 dockerd-current[3375]: time="2017-09-28T17:08:48.998079496-04:00" level=info msg="Loadin...one."
Sep 28 17:08:49 centos7 dockerd-current[3375]: time="2017-09-28T17:08:48.998264761-04:00" level=info msg="Daemon...tion"
Sep 28 17:08:49 centos7 dockerd-current[3375]: time="2017-09-28T17:08:48.998296244-04:00" level=info msg="Docker....12.6
Sep 28 17:08:49 centos7 systemd[1]: Started Docker Application Container Engine.
Sep 28 17:08:49 centos7 dockerd-current[3375]: time="2017-09-28T17:08:49.028663143-04:00" level=info msg="API li...sock"
Hint: Some lines were ellipsized, use -l to show in full.
{% endhighlight %}

The solution I've found most straightforward (but rather apathetic on the security
  front) is to change the permissions of the docker.sock file, but your
  userid must be in the dockerroot group:

{% highlight shell %}
[mbacchi@centos7 ~]$ grep docker /etc/group
dockerroot:x:990:mbacchi
[mbacchi@centos7 ~]$  ls -ltr /var/run/docker.sock
srw-rw----. 1 root root 0 Sep 28 17:08 /var/run/docker.sock
[mbacchi@centos7 ~]$  sudo chown root:dockerroot /var/run/docker.sock
[mbacchi@centos7 ~]$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
{% endhighlight %}
