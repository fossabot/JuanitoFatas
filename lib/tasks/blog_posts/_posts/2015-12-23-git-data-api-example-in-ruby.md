---
layout: post
title: Git Data API example in Ruby
date: 2015-12-23 14:36:03
description: Example to use GitHub's Git Data API.
tags: "git", "github", "ruby"
---

GitHub has a low-level [Git Data API](https://developer.github.com/v3/git/). You can do basically everything with `Git` via this powerful API!

![](https://cloud.githubusercontent.com/assets/1000669/17738548/3c96c1d2-64c4-11e6-8bc0-54a579b77f33.png)

In this tutorial, I am going to walk you through how to use this API with [Octokit](https://github.com/octokit/octokit.rb) to change files in one single commit in a new branch and send a Pull Request.

Suppose we want to send a Pull Request for https://github.com/JuanitoFatas/git-playground with these changes:
- append `bar` to file foo
- append `baz` to file bar
- in one commit with the message "Update foo & bar in a new topic branch "update-foo-and-bar".

This is how you could do it:

## 0. Install Octokit Gem

```
$ gem install octokit
```

## 1. Prepare Octokit Client

[Get an access token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/), and open irb with octokit required, then create an Octokit client with your token:

```ruby
$ irb -r octokit

> client = Octokit::Client.new(access_token: "<your 40 char token>")
```

We also prepare two variables to be used later, the repo name and new branch name:

```
repo = "JuanitoFatas/git-playground"
new_branch_name = "update-foo-and-bar"
```

## 2. Create a new Topic Branch

First, let's get the base branch (in this case, master branch) SHA1, so that we can branch from master.

We can use the [`Octokit#refs` method](http://octokit.github.io/octokit.rb/Octokit/Client/Refs.html#refs-instance_method) to get the base branch SHA1:

```ruby
master = client.refs(repo).find do |reference|
  "refs/heads/master" == reference.ref
end

base_branch_sha = master.object.sha
```

And creates a new branch from base branch via [`Octokit#create_ref` method](http://octokit.github.io/octokit.rb/Octokit/Client/Refs.html#create_ref-instance_method):

```ruby
new_branch = client.create_ref(repo, "heads/#{new_branch_name}", base_branch_sha)
```

The tricky part here is that you need to prefix your new branch name with `"heads/"`.

## 3. Change file contents

First let's use [`Octokit#contents` method](http://octokit.github.io/octokit.rb/Octokit/Client/Contents.html#contents-instance_method) with the SHA1 to get existing `foo` and `bar` files' content.

```ruby
foo = client.contents repo, path: "foo", sha: base_branch_sha
bar = client.contents repo, path: "foo", sha: base_branch_sha
```

Contents on GitHub API is Base64-encoded, we need to decode and append "bar" to `foo` file, "baz" to `bar` file respectively:

```ruby
require "base64"

# path => new content
new_contents = {
  "foo" => Base64.decode64(foo.content) + "bar",
  "bar" => Base64.decode64(foo.content) + "baz"
}
```

Creates a new tree with our new files (blobs), the new blob can be created via ([`Octokit#create_blob` method](http://octokit.github.io/octokit.rb/Octokit/Client/Objects.html#create_blob-instance_method)). This new tree will be part of our new “tree”.

```ruby
new_tree = new_contents.map do |path, new_content|
  Hash(
    path: path,
    mode: "100644",
    type: "blob",
    sha: client.create_blob(repo, new_content)
  )
end
```

## 4. Create a new commit with changes

Get the current commit first via [`Octokit#git_commit` method](http://octokit.github.io/octokit.rb/Octokit/Client/Commits.html#git_commit-instance_method):

```ruby
commit = client.git_commit(repo, new_branch["object"]["sha"])
```

Note that this method is not the same as [`Octokit#commit` method](http://octokit.github.io/octokit.rb/Octokit/Client/Commits.html#commit-instance_method). `git_commit` is from the low-level [Git Data API](https://developer.github.com/v3/git/), while `commit` is using the [Commits API](https://developer.github.com/v3/repos/commits/).

Now we get the commit object, we can retrieve the tree:

```ruby
tree = commit["tree"]
```

Creates a new tree by [`Octokit#create_tree` method](http://octokit.github.io/octokit.rb/Octokit/Client/Objects.html#create_tree-instance_method) with the blobs object we created earlier:

```ruby
new_tree = client.create_tree(repo, new_tree, base_tree: tree["sha"])
```

The `base_tree` argument here is important. Pass in this option to _update an existing tree with new data_.

Now our new tree is ready, we can add a commit onto it:

```ruby
commit_message = "Update foo & bar"
new_commit = client.create_commit(repo, commit_message, new_tree["sha"], commit["sha"])
```

## 5. Add commit to the new branch

Finally, update the reference via [`Octokit#update_ref` method](http://octokit.github.io/octokit.rb/Octokit/Client/Refs.html#update_ref-instance_method) on the new branch:

```ruby
client.update_ref(repo, "heads/#{new_branch_name}", new_commit["sha"])
```

## 6. Issue Pull Request

Creates a new Pull Request via [`Octokit#create_pull_request` method](http://octokit.github.io/octokit.rb/Octokit/Client/PullRequests.html#create_pull_request-instance_method):

```ruby
title = "Update foo and bar"
body = "This Pull Request appends foo with `bar`, bar with `baz`."
client.create_pull_request(repo, "master", new_branch_name, title, body)
```

That's it! :sparkles:  See the result [here](https://github.com/JuanitoFatas/git-playground/pull/1).

Now you can do basically everything with Git via GitHub's Git Data API!

May the Git Data API be with you.

Thanks for reading!

*Originally posted on https://github.com/jollygoodcode/jollygoodcode.github.io/issues/14.*
