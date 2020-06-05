---
layout: post
title:  "Empty greenhouse.io job posts"
date:   2017-08-24 10:15:00
comments: true
published: true
tags: troubleshooting, browser
redirect_to: https://bacchi.org/posts/greenhouse-iframe/
---

I was interested in a job description a company posted via Twitter, but I
couldn't view the text and didn't understand why. This wasn't the first time
this happened so decided to dig into the problem and determine if it was an
issue with my environment or the website.

My initial assumption was there was some problem with the company's website. But
they must test that these postings are visible occasionally right? Looking at
the page source there was no job description content, but rather this URL:

```
https://app.greenhouse.io/embed/job_board/js?for=fastly
```

Well this was a little unexpected but not totally surprising. They use a service
to host all their job openings and then embed it in an iframe on their site.
Could the iframe be a problem? I did a google search and found no hits
whatsoever. How could I be the first person to encounter this? I'm not an
experienced web developer but have been teaching myself some Python Pyramid
stuff lately. Lets see what the developer console says about the page.  It
indicated the error:

```
GET https://app.greenhouse.io/embed/job_board/js?for=fastly net::ERR_BLOCKED_BY_CLIENT
```

This told me that the server wasn't the problem but instead my client was
blocking the content. What now? Oh, ya, I have extensions such as Fair Adblocker
and Privacy Badger installed to prevent sites from tracking me. I looked to see
if those were blocking any greenhouse.io sites and sure enough, there were 4
URLs being blocked:

```
app.greenhouse.io
boards.greenhouse.io
boards-use1-cdn.greenhouse.io
boards-api.greenhouse.io
```

Once I disabled full blocking on those sites, and only enabled blocking of
cookies, I was able to view the iframe with the job description.

Hope this helps somebody (maybe even me) sometime in the future.
