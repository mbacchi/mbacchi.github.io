---
layout: post
title: "AWS CodeCommit SSH Key ID"
date: 2018-01-22 13:50:00
comments: true
published: true
tags: AWS CodeCommit
---

Working on AWS CodeCommit today, I setup SSH access to the repository. During the initial configuration I provided the SSH public key in the AWS Console, but then couldn't connect to my repository. In the brief instructions on the IAM Console page they tell you how to update your `~/.ssh/config` file, but the example doesn't explicitly say what the IdentityFile is supposed to be set to. In the more detailed instructions they do specify the IdentityFile should reference your <i><b>private key</b></i>, not your public key.

For others who are confused about this, and my future self, [here's the AWS documentation](https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-ssh-unixes.html?icmpid=docs_acc_console_connect#setting-up-ssh-unixes-keys) for how to configure SSH Key ID for CodeCommit.
