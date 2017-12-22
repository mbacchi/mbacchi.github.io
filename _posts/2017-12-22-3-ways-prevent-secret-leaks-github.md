---
layout: post
title: "3 Ways to Prevent .pypirc Credentials or Other Secrets from Leaking onto Github"
date: 2017-12-22 16:45:00
comments: true
published: true
tags: PyPi security github
---

Even if you're not involved in the Python community, you might have heard about
[this security
incident](http://python-security.readthedocs.io/pypi-vuln/index-2017-11-08-pypirc_exposure_on_github.html)
a while back. This is a not uncommon scenario where developers who may not be
Github or distribution tooling (or security) experts make a mistake and breed
mistrust in their project as well as the distribution medium itself.

But setting up your environment to prevent these accidental credential disclosures
is easy to do, and will enhance your security posture.

Here are a few ways to prevent these exposures with git and other tools.

#### Add the .pypirc file to the .gitignore list

This is the most straightforward, and will force git to ignore the `.pypirc` when
you're adding/committing changes to the repository.

I typically use my global `.gitignore` file, but you can also add it to the
repository specific `.gitignore` file. Here's how to do both.

Create a `~/.gitignore` and make this your personal git core.excludesfile:

```
[mbacchi@hostname test-pypi]$ git config --global core.excludesfile=~/.gitignore
[mbacchi@hostname test-pypi]$ git config -l --global | grep core.excludesfile
core.excludesfile=~/.gitignore
[mbacchi@hostname test-pypi]$ echo ".pypirc">> ~/.gitignore
[mbacchi@hostname test-pypi]$ cat ~/.gitignore
.idea
.pypirc
```

Now you can test whether this will work using the `git check-ignore` command:

```
[mbacchi@hostname test-pypi]$ git check-ignore -v .pypirc
/home/mbacchi/.gitignore:4:.pypirc	.pypirc
[mbacchi@hostname test-pypi]$ echo $?
0
```

If you want to add it to the project repository instead, simply perform the
same operation on the `.gitignore` file in the repository. But be aware that
unless you also commit the `.gitignore` file into the repository this ignore
will lost upon removing and recreating this repository.

#### Add a git pre-commit hook to your git repository that will analyze the staged files for .pypirc

In order to use a git pre-commit hook, first add the file `pre-commit` to the
.git/hooks directory in your repository:

```
[mbacchi@hostname test-pypi]$ cat .git/hooks/pre-commit
#!/bin/sh
#
# A git hook to check whether .pypirc files exist in the staged files list

PYPIRC=$(git status -s| grep .pypirc)

if [[ "$PYPIRC" == *".pypirc"* ]]; then
    # .pypirc is included in the staged files
    echo "ERROR: [pre-commit hook] Aborting commit because you have the file .pypirc staged to be committed."
    echo "Remove it from the repository using \"git rm --cached .pypirc\""
    echo
    echo "You should also move your .pypirc file to your home directory with the command \"mv .pypirc ~\""
    exit 1
else
    # not found
    exit 0
fi
```

Make sure it is executable, if it can't execute it won't function correctly
in the git workflow:

```
[mbacchi@hostname test-pypi]$ chmod 744 .git/hooks/pre-commit
[mbacchi@hostname test-pypi]$ ls -l .git/hooks/pre-commit
-rwxr--r--. 1 mbacchi mbacchi 533 Dec 22 15:17 .git/hooks/pre-commit
```

This will do a `git status` and grep the output for the `.pypirc` file, if found
it will return 1, which tells `git commit` to abort.

Now, test that it works as expected:

```
[mbacchi@hostname test-pypi]$ git add .pypirc
[mbacchi@hostname test-pypi]$ git status
On branch master

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)

	new file:   .pypirc
Untracked files:
  (use "git add <file>..." to include in what will be committed)

	LICENSE.txt
	README.rst
	blah/
	kerplunk/
	setup.cfg
	setup.py

[mbacchi@hostname test-pypi]$ git commit
ERROR: [pre-commit hook] Aborting commit because you have the file .pypirc staged to be committed.
Remove it from the repository using "git rm --cached .pypirc"

You should also move your .pypirc file to your home directory with the command "mv .pypirc ~"
[mbacchi@hostname test-pypi]$ echo $?
1
```

NOTE: This does only work on the repository level, it can't be added to your
personal git configuration to be used for all repos you work in.

#### Use git-secrets to perform analysis of your current staged files, as well as the repository's commit history for secret keys

Not specific to `.pypirc` credentials, we have also heard
[stories](https://www.theregister.co.uk/2017/11/14/dxc_github_aws_keys_leaked/)
of people accidentally leaking AWS or other private keys (think SSH id_rsa
vs. id_rsa.pub files for example) on Github. Not excited about doing this
yourself? Me either. So here's one way I've been analyzing both my current
git repository commits, as well as my git history.

Using the AWS Labs developed
[git-secrets](https://github.com/awslabs/git-secrets) we can setup our
global git config to prevent strings that look like AWS Access Key ID or AWS
Secret Access Key strings to be committed to git repositories and Github.

Clone and install the `git-secrets` bash script in your personal bin tree:

```
[mbacchi@hostname repos]$ git clone git@github.com:awslabs/git-secrets.git
Cloning into 'git-secrets'...
remote: Counting objects: 250, done.
remote: Compressing objects: 100% (7/7), done.
remote: Total 250 (delta 2), reused 2 (delta 0), pack-reused 243
Receiving objects: 100% (250/250), 80.42 KiB | 1.36 MiB/s, done.
Resolving deltas: 100% (141/141), done.
[mbacchi@hostname repos]$ cd git-secrets/
[mbacchi@hostname git-secrets]$ cp git-secrets ~/bin
[mbacchi@hostname git-secrets]$ cd ../test-pypi/
[mbacchi@hostname test-pypi]$ git-secrets --help
usage: git secrets --scan [-r|--recursive] [--cached] [--no-index] [--untracked] [<files>...]
   or: git secrets --scan-history
   or: git secrets --install [-f|--force] [<target-directory>]
   or: git secrets --list [--global]
   or: git secrets --add [-a|--allowed] [-l|--literal] [--global] <pattern>
   or: git secrets --add-provider [--global] <command> [arguments...]
   or: git secrets --register-aws [--global]
   or: git secrets --aws-provider [<credentials-file>]

    --scan                Scans <files> for prohibited patterns
    --scan-history        Scans repo for prohibited patterns
    --install             Installs git hooks for Git repository or Git template directory
    --list                Lists secret patterns
    --add                 Adds a prohibited or allowed pattern, ensuring to de-dupe with existing patterns
    --add-provider        Adds a secret provider that when called outputs secret patterns on new lines
    --aws-provider        Secret provider that outputs credentials found in an ini file
    --register-aws        Adds common AWS patterns to the git config and scans for ~/.aws/credentials
    -r, --recursive       --scan scans directories recursively
    --cached              --scan scans searches blobs registered in the index file
    --no-index            --scan searches files in the current directory that is not managed by Git
    --untracked           In addition to searching in the tracked files in the working tree, --scan also in untracked files
    -f, --force           --install overwrites hooks if the hook already exists
    -l, --literal         --add and --add-allowed patterns are escaped so that they are literal
    -a, --allowed         --add adds an allowed pattern instead of a prohibited pattern
    --global              Uses the --global git config
```

We're going to register the AWS secret patterns in the test-pypi repository:

```
[mbacchi@hostname test-pypi]$ git-secrets --register-aws
[mbacchi@hostname test-pypi]$ git config -l | grep secrets
secrets.providers=git secrets --aws-provider
secrets.patterns=[A-Z0-9]{20}
secrets.patterns=("|')?(AWS|aws|Aws)?_?(SECRET|secret|Secret)?_?(ACCESS|access|Access)?_?(KEY|key|Key)("|')?\s*(:|=>|=)\s*("|')?[A-Za-z0-9/\+=]{40}("|')?
secrets.patterns=("|')?(AWS|aws|Aws)?_?(ACCOUNT|account|Account)_?(ID|id|Id)?("|')?\s*(:|=>|=)\s*("|')?[0-9]{4}\-?[0-9]{4}\-?[0-9]{4}("|')?
secrets.allowed=AKIAIOSFODNN7EXAMPLE
secrets.allowed=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

Now using an AWS credential file that I made invalid immediately after
creating(seriously, this won't work if you try using it), I will scan the
repository for secrets:

```
[mbacchi@hostname test-pypi]$ cat aws-credentials
[default]
aws_access_key_id=AKIAISITMFSJISKWFAJX
aws_secret_access_key=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

[mbacchi@hostname test-pypi]$ git-secrets --scan -r .
./aws-credentials:2:aws_access_key_id=AKIAISITMFSJISKWFAJX
./aws-credentials:3:aws_secret_access_key=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

[ERROR] Matched one or more prohibited patterns

Possible mitigations:
- Mark false positives as allowed using: git config --add secrets.allowed ...
- Mark false positives as allowed by adding regular expressions to .gitallowed at repository's root directory
- List your configured patterns: git config --get-all secrets.patterns
- List your configured allowed patterns: git config --get-all secrets.allowed
- List your configured allowed patterns in .gitallowed at repository's root directory
- Use --no-verify if this is a one-time false positive
```

This could be setup for other patterns of course but AWS is the most
straightforward and frequently committed to Github repositories. You can also
scan the commit history for previously committed secrets.

Using the steps above, you could create a pre-commit hook for your git
repository to prevent secrets from being committed to git.

Hope these suggestions make their way into your personal or team's workflow to
make you more secure!
