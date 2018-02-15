---
layout: post
title: Checkout Pull Request locally
date: 2018-02-09 15:27:45
description: Two ways to checkout Pull Request locally and apply Pull Request on any branch.
tags: "git", "github"
---

Suppose the Pull Request we want is https://github.com/bundler/bundler/pull/6282:

```
git fetch origin pull/6282/head:pr-6282
git checkout pr-6282
```

as [GitHub suggested](https://help.github.com/articles/checking-out-pull-requests-locally/).

There is a [`git fetch-pr` script][git-fetch-pr] available.

Or

you can follow [this gist](https://gist.github.com/piscisaureus/3342247) to add an alias, then:

```
git fetch origin
git checkout pr/6292
```

Apply Pull Request on any branch:

```
git am -3 https://github.com/bundler/bundler/pull/6282
```

Please see [git-am docs](https://git-scm.com/docs/git-am).

Happy checking!

[git-fetch-pr]: https://github.com/JuanitoFatas/bin/blob/44445529df098b8aa534183496a6a77ac1eb0006/git-fetch-pr
