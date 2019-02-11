A git wrapper to provide additional features around working with stories.

## Overview

gitcli is an extended git CLI tool written in bash. It is written to stop fiddling around creating
new stories, managing remote branches, switching between working branches while reserving the
context.

gitcli is designed to work well with any git repository.

## Dependencies
* mapfile --- On MacOS, do `brew install bash` to install mapfile binary
* bats --- Follow the instructions at https://github.com/sstephenson/bats to run the tests

## Usages

### Creating new story

Add *source* to git config

```
$> git config story.source.SOURCE_IDENTIFIER SOURCE_BRANCH_NAME
```

Add *remote target* to git config

```
$> git config story.remotetarget TARGET_REMOTE_NAME
```

Then run the gitcli command to create new branch.

```
$> gitcli s[tory] n[ew] -s SOURCE_IDENTIFIER -b NEW_BRANCH_NAME
```

Following operations will be executed in the order.

* Stash any changes on current branch and store the stash hash in git config
* Fetch most recent changes of `SOURCE_BRANCH_NAME` from its remote
* Create new branch `NEW_BRANCH_NAME` off of `SOURCE_BRANCH_NAME` by referencing it via `SOURCE_IDENTIFIER`
* Push new local branch to `TARGET_REMOTE_NAME`

For example, in the following case,

* I forked my repo from FooBar/master into origin/master
* I need to push local branch to origin/feature-branch-1
* I need to create a pull request against FooBar/master

I run these commands to create my new local branch.

```
$> git config story.source.master FooBar/master
$> git config story.remote.target origin
$> gitcli s n -s master -b feature-branch-1
```

### Switching to story

Switch to an existing local branch

```
$> gitcli s[tory] s[witch] [-r] [-p PATTERN]
```

This command displays an enumerated list of local branches. If a branch is selected, the following
operations will be executed.

* Stash any changes on current branch and store the stash hash in git config
* Checkout the chosen branch
* Pop out the stored stash if switched branch had one mapped to it in git config

If `-r` flag is set, it will switch to the most recent branch.

If `PATTERN` is specified, only branches whose names regex-match with the PATTERN will be presented.

### Pulling recent changes

Add *source* to git config

```
$> git config story.source.SOURCE_IDENTIFIER SOURCE_BRANCH_NAME
```

Then run the gitcli command to pull most recent changes into current branch

```
$> gitcli s[tory] p[ull] -s SOURCE_IDENTIFIER
```

Then following operations will be executed in the order.

* Fetch most recent changes of `SOURCE_BRANCH_NAME` from its remote
* Attempt to merge `SOURCE_BRANCH_NAME` into current local branch

For example, in the following case,

* I forked my repo from FooBar/master into origin/master
* I need to create a pull request against FooBar/master
* I need to pull most recent changes of FooBar/master to make sure I don't have any conflict in my PR

I run these commands to pull.

```
$> git config story.source.master FooBar/master
$> gitcli s p -s master
```

If there are any conflicts, you will get an error message saying you have unstashed changed. Local
change will need to stashed before running this command.

### Opening Pull Request page in browser

Add *source* to git config

```
$> git config story.source.SOURCE_IDENTIFIER SOURCE_BRANCH_NAME
```

Then run the gitcli command to open a link to create pull request
for current branch merging into `SOURCE_IDENTIFIER` repository.

```
$> gitcli story p[ull]r[equest] -s SOURCE_IDENTIFIER
```

For example, in the following case,

* I forked my repo from FooBar/master into origin/master
* I created a new feature branch feature/new-feature with origin/new-feature as upstream
* I need to create a pull request against FooBar/master

I run these commands to open pull request link.

```
$> git config story.source.master FooBar/master
$> gitcli s pr -s master
```

This will open a pull request to merge feature/new-feature into FooBar/master

## Bonus

I have my `git` command setup in the following way.

```
git () {
    customCmds=("s" "story")
    if [[ ${customCmds[(i)$1]} -le ${#customCmds} ]]; then
        gitcli "$@"
    else
        /usr/bin/git "$@"
    fi
}
```

This lets me use `git story new/switch/pull/pullrequest` as if I am using the native git client.

## Author

[kidonchu](https://github.com/kidonchu)

## License

MIT
