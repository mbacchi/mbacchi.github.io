---
layout: post
title:  "Running Brave in a Docker Container"
date:   2019-09-11 19:00:00
comments: true
published: true
tags: brave docker container chromium chrome
---

Security minded users often run Docker to create an additional sandbox around an
untrusted application running on their system. Web Browsers are among the most
untrusted applications we run today. Here's how to setup the Brave Browser to
run in Docker.

To paraphrase T.S. Eliot, 'good coders borrow and great coders steal.' So I'll
be borrowing from Jess Frazelle's work on running Chromium<!--more--> in
[Docker](https://github.com/jessfraz/dockerfiles/blob/master/chromium/Dockerfile)
and using her
[seccomp](https://github.com/jessfraz/dotfiles/blob/master/etc/docker/seccomp/chrome.json)
profile. This specifically provides the list of system calls that Chromium or in
our case Brave can run in the Docker container.

#### Install and Configure Docker

You will first need to install Docker on your machine and make sure the daemon
is running. To verify your system is configured to run Docker, try running the
`hello-world` image:

{% highlight shell %}
[user@host ~]$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
1b930d010525: Pull complete 
...
{% endhighlight %}

If it doesn't run there are
[many](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
[guides](https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/configure-docker-daemon)
to configuring Docker available.

#### Brave in Docker

In order to run Brave in Docker clone the
[brave-github](https://github.com/mbacchi/brave-docker) GitHub repository.

The Dockerfile in this repository uses a basic Fedora image to install Brave
from the [release channel RPM
repository](https://brave-browser.readthedocs.io/en/latest/installing-brave.html#linux).

Follow these steps to setup additional prereqs:
1. Change into the brave-docker directory after cloning: `cd brave-docker`
2. Next, you'll need to download the seccomp profile from [here](https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json): `wget https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json -O chrome.json`
3. Add xhost permissions for your user using [the command](https://github.com/jessfraz/dockerfiles/issues/65#issuecomment-304463458) (It's probably good to come up with a more restrictive method than opening up xhost to all clients.): `xhost +`

#### Building the Docker image

To build the image, run:

{% highlight shell %}
[user@host brave-docker]$ docker build . -t brave-release-fedora
{% endhighlight %}

You can use any tag you like, just replace the `-t` argument above.

To list your image after building, run the command:

{% highlight shell %}
[user@host brave-docker]$ docker images
REPOSITORY             TAG                 IMAGE ID            CREATED              SIZE
brave-release-fedora   latest              729a66f5a7cf        About a minute ago   1.08GB
{% endhighlight %}

#### Running the container

To run Brave in the image you built, use the `docker run` command:

{% highlight shell %}
[user@host brave-docker]$ docker run -it --net host --cpuset-cpus 0 --memory 512mb \
-v $HOME/Downloads:/home/brave/Downloads:z -v /tmp/.X11-unix:/tmp/.X11-unix \
--security-opt seccomp=./chrome.json -e DISPLAY=unix$DISPLAY --device /dev/dri \
-v /dev/shm:/dev/shm --device /dev/snd brave-release-fedora
{% endhighlight %}

It will default to using UID/GID 1000 for the `brave` user in the container.
This will allow you to mount your `~/Download` directory as a volume in the
container, in order to download files as you would using a browser normally in
your environment. If you need to change the UID/GID, pass the flag `--build-arg
UID_GID=YOUR_UID` to the `docker build` command in the previous section.

Have fun!
