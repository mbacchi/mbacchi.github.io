---
layout: post
title: "Using Git hook templates to avoid committing secrets to public repositories"
date: 2018-05-11 21:00:00
comments: true
published: true
tags: git security github aws
---

Git doesn't have the concept of a per user global hook. It would be nice if you could create hooks in your home directory that could be executed in all repositories that work with. Instead, it does allow you to write hooks that reside in a user specific template directory to then be copied into any repositories that you clone or create from scratch.

After following this guide to configure template hooks, when you clone or create a new repository using the `git init` command, your hooks will be copied into your new repositories.

#### Why would I want hooks in every new repository?

There could be many reasons why you want to setup a hook in every new repository. My current use case has to do with preventing AWS credentials from accidentally being committed to any of my GitHub repositories. This prevents you from having someone get into your AWS account and potentially racking up a large bill you would be responsible for. Automatically scanning your commit for any patterns that look like AWS secrets will prevent this costly mistake.

#### Template configuration

The `git init` [man page](https://git-scm.com/docs/git-init#_template_directory) talks about the Template Directory which gives us the ability to copy hooks into new repositories. It must first be configured using the `git config` command, specfying the [`init.templatedir`](https://git-scm.com/docs/git-config#git-config-inittemplateDir) which is the directory where you will store your hooks. You will run a command such as:

```
git config --global init.templatedir '~/.git_template'
```

This config directive is added to the `[init]` section in your `.gitconfig` file, which looks like the following:

```
[init]
	templatedir = ~/.git_template
```

#### Create the hook

Now we can create our hook and place it in the template hooks directory (which is actually templatedir/hooks). This hook employs `git-secrets` to prevent me from accidentally committing my AWS credentials to GitHub:

```
#!/bin/bash
#
# A git hook to run git-secrets (locally 'installed') against a repository.
# This should be extended to do much more verification and error handling,
# but is presented as a demonstration.
#
# This assumes you've already setup git-secrets patterns (i.e. "git-secrets --register-aws").

# Verify that the git-secrets file is in our path
secretspath=$(which git-secrets)
if [[ -z "${secretspath}" || ! -x "${secretspath}" ]]; then
  echo "git-secrets not found!"
  exit 1
fi

RESPONSE=`git-secrets --scan -r .`
RC=$?

if [[ $RC -eq 1 ]]; then
    # return code 1 from git-secrets indicates scan found a verboten string
    echo
    echo
    echo "ERROR: [pre-commit hook] Aborting commit because git-secrets found a prohibited pattern in this repository"
    echo "Please remove the file with the pattern in the output above from this repository!"
    echo
    exit 1
else
    # no secrets found in repo
    exit 0
fi
```

Looking in that directory we see the new hook, but we need to make it executable so I will run the command `chmod 744` on the file:

```
[user1@host hooks]$ chmod 744 ~/.git_template/hooks/pre-commit
[user1@host hooks]$ ls -l ~/.git_template/hooks
total 4
-rwxrw-r--. 1 user1 user1 931 May 11 20:34 pre-commit
```

#### Prepare a file containing a pattern that will fail the git-secrets scan

At this point we will create a new directory to test our hook. Start by creating a directory to work in:

```
[user1@host repos]$ mkdir template-dir-demo && cd template-dir-demo
```

Then create a file with a string that looks like an AWS secret(hint, the AWS secret access key is a 40 character string containing lower, upper and digit characters):

```
[user1@host template-dir-demo]$ ipython
Python 3.6.4 (default, Mar 13 2018, 18:18:20)
Type 'copyright', 'credits' or 'license' for more information
IPython 6.2.1 -- An enhanced Interactive Python. Type '?' for help.

In [1]: import random

In [2]: from string import ascii_uppercase, ascii_lowercase, digits

In [3]: chars = ascii_uppercase + ascii_lowercase + digits

In [4]: key = ''.join(random.choice(chars) for _ in range(40))

In [5]: key
Out[5]: 'dbMi8e8YYNnTUnlTEEyyYbK3KfQExuaRXF8roC9d'

[user1@host template-dir-demo]$ echo 'aws_secret_access_key = dbMi8e8YYNnTUnlTEEyyYbK3KfQExuaRXF8roC9d' > blah1.txt
[user1@host template-dir-demo]$ cat blah1.txt
aws_secret_access_key = dbMi8e8YYNnTUnlTEEyyYbK3KfQExuaRXF8roC9d
```

Now we will run `git init .` to initialize a git repository in the current directory, and we see that the pre-commit hook is copied from the template directory:

```
[user1@host template-dir-demo]$ git init .
Initialized empty Git repository in /home/user1/repos/template-dir-demo/.git/
[user1@host template-dir-demo]$ ls -altr .git/hooks/
total 12
-rwxrwxr-x. 1 user1 user1  931 May 11 20:39 pre-commit
```

#### Perform a commit

Finally, lets stage and commit the file and see if the pre-commit hook allows the file to be staged and committed:

```
[user1@host template-dir-demo]$ git add blah1.txt
[user1@host template-dir-demo]$ git commit -m "blah1 file with a secret"
./blah1.txt:1:aws_secret_access_key = dbMi8e8YYNnTUnlTEEyyYbK3KfQExuaRXF8roC9d

[ERROR] Matched one or more prohibited patterns

Possible mitigations:
- Mark false positives as allowed using: git config --add secrets.allowed ...
- Mark false positives as allowed by adding regular expressions to .gitallowed at repository's root directory
- List your configured patterns: git config --get-all secrets.patterns
- List your configured allowed patterns: git config --get-all secrets.allowed
- List your configured allowed patterns in .gitallowed at repository's root directory
- Use --no-verify if this is a one-time false positive


ERROR: [pre-commit hook] Aborting commit because git-secrets found a prohibited pattern in this repository
Please remove the file with the pattern in the output above from this repository!
```

As you can see using a Git template for hooks will help us automatically setup hooks to use in any new repository whether it is cloned or created with the `git init` command.

I hope this was helpful to you.
