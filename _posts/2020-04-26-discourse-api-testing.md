---
layout: post
title:  "Testing the Discourse API"
date:   2020-04-26 21:00:00
comments: true
published: true
tags: api docker container discourse
---

Discourse is used for a number of purposes, but their forum software is quite popular. I've been looking at how to us the [Discourse API](https://docs.discourse.org/) to
automate creating posts. This blog post describes how to setup a local Discourse
instance and perform API calls against it.

## Setup Discourse Container

This step is fairly straightforward thanks to [Bitnami's Discourse Docker
container](https://github.com/bitnami/bitnami-docker-discourse) which launches
and configures all the components in a Docker Compose environment.

At first I just tried to launch it with `docker compose up -d` and while it
appeared to start and run successfully I couldn't see anything in my browser. I
then read that you have to set the `DISCOURSE_HOSTNAME` to the IP address you
want to run Discourse on. If you're running on localhost, set it to `127.0.0.1`.
This [issue](https://github.com/bitnami/bitnami-docker-discourse/issues/100)
cleared it up for me.

So after editing the `docker-compose.yml` file, it now looks like this, and is
ready to start Discourse:

```
git diff docker-compose.yml
diff --git a/docker-compose.yml b/docker-compose.yml
index 1acf76d..51bc761 100644
--- a/docker-compose.yml
+++ b/docker-compose.yml
@@ -30,7 +30,7 @@ services:
       - DISCOURSE_POSTGRESQL_NAME=bitnami_application
       - DISCOURSE_POSTGRESQL_USERNAME=bn_discourse
       - DISCOURSE_POSTGRESQL_PASSWORD=bitnami1
-      - DISCOURSE_HOSTNAME=www.example.com
+      - DISCOURSE_HOSTNAME=127.0.0.1
   sidekiq:
     image: 'bitnami/discourse:2'
     depends_on:
```

Now run docker-compose, with the command:

```
docker-compose up -d
```

Wait a minute for the application to come up and continue on to the next section. If you want to query the containers to verify they are all up, you'll see 4 of them, similar to:

```
docker ps -a
CONTAINER ID        IMAGE                                                 COMMAND                  CREATED             STATUS                     PORTS                  NAMES
b4e5a2298efe        bitnami/discourse:2                                   "/app-entrypoint.sh …"   25 hours ago        Up 12 hours                3000/tcp               bitnami-docker-discourse_sidekiq_1
cbe2a7800486        bitnami/discourse:2                                   "/app-entrypoint.sh …"   25 hours ago        Up 12 hours                0.0.0.0:80->3000/tcp   bitnami-docker-discourse_discourse_1
c84794c82b3b        bitnami/postgresql:11                                 "/opt/bitnami/script…"   29 hours ago        Up 12 hours                5432/tcp               bitnami-docker-discourse_postgresql_1
2c00b3c124a2        bitnami/redis:5.0                                     "/opt/bitnami/script…"   29 hours ago        Up 12 hours                6379/tcp               bitnami-docker-discourse_redis_1

```

## Create a Discourse User

For this test, I don't need to setup SMTP email because I'm really only trying
out the Discourse API locally. Unfortunately Discourse relies on SMTP to
send emails for every user registration, even the first user signup process. For our purposes, we don't need email
capability, we only need a user to login and create an API token.

This can be accomplished using the following steps.

1. Connect to the discourse container:

    ``` bash
    [user@host bitnami-docker-discourse]$ docker exec -it bitnami-docker-discourse_discourse_1 /bin/bash
    ```

2. Using the steps for "Need to log in without receiving a registration email?" in the [email troubleshooting](https://meta.discourse.org/t/troubleshooting-email-on-a-new-discourse-install/16326/2) documentation as a guide, we'll run `rake` to create an admin account:

       root@cbe2a7800486:/opt/bitnami/discourse# pwd
       /opt/bitnami/discourse
       root@cbe2a7800486:/opt/bitnami/discourse# RAILS_ENV=production bundle exec rake admin:create
       Email:  myuser@example.com
       Password:  
       Repeat password:  

       Ensuring account is active!

       Account created successfully with username myuser
       Do you want to grant Admin privileges to this account? (Y/n)  y

       Your account now has Admin privileges!

3. Login to the Discourse GUI using the user/password you created above

## Create API Key

Next we'll create the API key that we're going to use to create posts. Follow these steps:

1. Go to the Admin page (hamburger menu in upper right)
2. Click on the API tab at the top
3. Select "New API Key"
4. Plug in your username, the description, and the user level of "Single User"

Write down the key because you'll never see it in full again if you forget it. (But of course you can create a new one and delete this one very easily.)

## Create New Category

You can create a new category via the GUI, but to do this via the API use a command similar to:

```
curl -X POST "http://127.0.0.1/categories.json" -H "Content-Type: application/json;" -H "Api-Key: 1234512345" -H "Api-Username: myuser" --data '{"name": "New Category", "color": "b3e0ff", "text_color": "000000"}'

{"category":{"id":6,"name":"New Category","color":"b3e0ff","text_color":"000000","slug":"new-category"
...
```

The new category ID (as shown in the response,) is `6`.

## Create a Post in the New Category

To finally perform the post creation using the API, do something like:

```
curl -X POST "http://127.0.0.1/posts.json" -H "Content-Type: application/json;" -H "Api-Key: 1234512345" -H "Api-Username: myuser" --data '{"title": "This is a new post in the newest category!", "category": 6, "raw": "This is the body for the new post"}'

{"id":24,"name":null,"username":"myuser","avatar_template":"/letter_avatar_proxy/v4/letter/m/9de0a6/{size}.png","created_at":"2020-04-27T03:12:10.295Z","cooked":"\u003cp\u003eThis is the body for the new post
...
```

And now you've created a new post using the API. Mission accomplished! (For real, not like with W.)

