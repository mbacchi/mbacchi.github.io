---
layout: post
title: "3rd Party Github Credential Scanning"
date: 2018-01-20 22:00:00
comments: true
published: true
tags: github security
redirect_to: https://bacchi.org/posts/github-scanning-3rd-parties/
---

While writing [a Python library](https://github.com/mbacchi/python-git-secrets)
that performs scanning of Git repositories similar to AWS Labs'
[git-secrets](https://github.com/awslabs/git-secrets), I was surprised by some
3rd party scanning services randomly scanning my repository for AWS credentials.
I had included deactivated AWS credentials in my repository so that I could test
my library. My plan was to replace these credentials with a randomly generated
string later on but at first I was satisfied to commit the actual (but not
active) credentials to Github themselves.

A couple weeks after I created the repository on Github, I got an email from a
random address named 'githubbot'. In the email they indicated that they had
found a credential in my repository. As a reward for notifying me of this
potentially costly situation, the email indicated I could send them bitcoin, and
they included the wallet address. Below is the email itself:

![githubbot email]({{ site.baseurl }}/img/githubbot.png){: .center-image }{:height="900px" width="500px"}

Later that day, in order to remove the credential file used in testing, I pushed
a commit that moved the credential strings in the test driver itself. Within an
hour I got an email from another unrelated service GitGuardian, indicating I
exposed an API key in my repository. Who knew so many good samaritan services
existed to help people out. Here's this email:

![gitguardian email]({{ site.baseurl }}/img/gitguardian.png){: .center-image }{:height="900px" width="770px"}

What I realized from this encounter is that there are all kinds of unknown
actors in the Github universe. Some will be benevolent like these, but there
very well could be black hat types who are scanning every public repository for
ways to get ahold of your AWS or other keys and will take advantage of them.

Watch what you do with your keys!!!! If you want some pointers on how to prevent
releasing credentials accidentally to Github, take a look at my recent [blog
post on preventing secret leaks]({{ site.baseurl }}{% post_url
2017-12-22-3-ways-prevent-secret-leaks-github %}).
