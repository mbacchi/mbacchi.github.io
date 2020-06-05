---
layout: post
title:  "Vagrant NFS synced_folders"
date:   2017-01-15 10:56:00
comments: true
tags: vagrant
redirect_to: https://bacchi.org/posts/vagrant-nfs-synced-folders/
---

After upgrading to Fedora 25 yesterday, Vagrant 1.8.5 in the updates repo was
unusable with VirtualBox for 2 reasons:

1. The newest centos/7 box didn't use vbox guest additions for shared folders, forcing the use of NFS
2. Vagrant issue [8138](https://github.com/mitchellh/vagrant/issues/8138 "Issue 8138") which is not fixed in the newest RPM from Vagrant means I had to install from source.

This required two workarounds in my Vagrantfile:

1. The setting config.vm.synced_folder requires the 'type: \"nfs\"' parameter.
2. The config.vm.provision section required the 'chef.synced_folder_type = \"nfs\"' parameter.

This looks like the following now:

{% highlight ruby %}
...
  config.vm.network "private_network", ip: "10.10.10.12"
  config.vm.synced_folder "django3", "/django3", type: "nfs"

  config.berkshelf.enabled = true

  config.vm.provision :chef_solo do |chef|
    chef.synced_folder_type = "nfs"
    chef.cookbooks_path = "cookbooks"
    chef.roles_path = "roles"
...
{% endhighlight %}
