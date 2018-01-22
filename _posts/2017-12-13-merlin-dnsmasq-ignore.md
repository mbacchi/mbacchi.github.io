---
layout: post
title: "Using dnsmasq on Asuswrt-merlin to ignore MAC addresses"
date: 2017-12-13 12:15:00
comments: true
published: true
tags: wifi asuswrt-merlin dnsmasq
---

Here's another 'for posterity' type post. I forgot I had configured my WiFi router
to ignore certain MAC addresses and when I tried to put that machine on the Network
today I had a rude awakening. Using the asuswrt-merlin firmware on my RT-AC66U
router, I had configured things to allow 2 machines to be served DHCP from another
PC so that I could run Cobbler on that machine and boot/kickstart these two hosts
just by hitting the power button. But when I disconnected this Cobbler server at
the beginning of my renovation, I forgot the MAC addresses were being ignored by
the router.

In order to enable these MAC addresses on the WiFi router I first tried
to comment the lines out, but then instead moved the config file to root's home
dir. Also I had to reboot the router:

{% highlight shell %}
admin@RT-AC66U:/tmp/home/root# mv /jffs/configs/dnsmasq.conf.add .
admin@RT-AC66U:/tmp/home/root# ls
dnsmasq.conf.add
admin@RT-AC66U:/tmp/home/root# more dnsmasq.conf.add
# 12/13/2017 comment these out while other dhcp server isn't available
#dhcp-host=ec:a8:6b:f4:ce:01,ignore
#dhcp-host=ec:a8:6b:f5:a4:ed,ignore
admin@RT-AC66U:/tmp/home/root# ls -ltr /jffs/configs/
admin@RT-AC66U:/tmp/home/root# reboot
{% endhighlight %}
