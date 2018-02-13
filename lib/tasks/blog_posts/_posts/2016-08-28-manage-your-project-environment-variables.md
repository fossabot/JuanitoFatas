---
layout: post
title: "Manage Your Project's Environment Variables"
date: 2016-08-28 18:00:00
description: "Manage your Rails project's environment variables with dotenv gem."
tags: "rails", "practice", "environment"
---

This post shares how to manage your project's environment variables for development, test, and production.

## Why Store Configs in Environment Variable?

[The Twelve-Factor App][12factor-app] says [store your config in the environment][store-config-in-env], and already explained very well.

## How do we manage?

We will manage our env using [dotenv][dotenv] gem. This gem can be used with both Ruby project & Rails project, we will focus Rails here.

First [install][install] it, and create a `.env` file that contains something like this as a starting point:

```
# Don't modify this file. Create `.env.local` and put your overrides in there.
HOST=localhost:3000
```

## Use the ENV variable

Prefer [`ENV.fetch("HOST")`][env-fetch] over `ENV["HOST"]` because it fails fast. You can provide default value in the block form:

```ruby
ENV.fetch("HOST") { "localhost:3000" }
```

because [it is faster](https://github.com/JuanitoFatas/fast-ruby#hashfetch-with-argument-vs-hashfetch--block-code).

## dotenv-recognized Files

- `.env`

  Common ENVs across all environments.

- `.env.test`

  ENVs for the test environment.

- `.env.development`

  ENVs for the development environment.

- `.env.local`

  ENVs for local environment (development, test).

### The load order of dotenv

1. First, dotenv loads the `.env` first
2. Second, dotenv loads the `.env.{test, development}`
3. Finally, dotenv loads the `.env.local`

### Commit .env or not?

The old practice is to create something like `.env.sample`, `.env.development.sample`, and `.env.test.sample`. Then you copy those to `.env`, `.env.development`, and `.env.test` respectively. Also, you will need to copy them again on Continuous Integration. This adds up to 6 files that I consider as an overhead. Things should just work out of the box, so what I propose is to only work with `.env` and `.env.local`.

So don't put any sensitive information in `.env` and commit it to version control, easier setup for both the people you're working with and on the Continuous Integration. [Here is an example change on how you can migrate to what I proposed](https://github.com/houndci/hound/commit/37edd8de16360c1d6de85fb8f4e3ab979adb3d23).

### Overrides at .env.local

During development, there are some ENV that will need to be real, like OAuth app id and secret.

Put your real (sensitive) values in `.env.local` at local:

```
# .env.local
OAUTH_APP_ID=top_secret_oauth_app_id
OAUTH_APP_SECRET=top_secret_oauth_app_secret
```

And you MUST ignore this file to version control:

```
# .gitignore
.env.local
```

**:warning: NEVER PUT REAL INFORMATION IN `.env`.**

## Test Environment

Alought dotenv provides `.env.test` that you can put test ENVs in, but then we need to working with one more file and I bet this is rarely the case. And sometimes we will need to test when ENV changes.

So for the test environment, I suggest you provide a fake value by yourself in relevant places. Avoid use of `env.test` because it introduces [Mystery Guest][mystery-guest].

How do you manage environment variables & testing, please see this excellent post: [Testing and Environment Variables](https://robots.thoughtbot.com/testing-and-environment-variables).

## Production-like environment

Find out how to set/get/unset those ENVs on your production-like (staging, production) server, on Heroku is as simple as:

```bash
# Set a ENV
$ heroku config:set GITHUB_TOKEN=78a326b40bf6a7bfd80b0377445707523dfc4b299366942d19904fafe685afe6426d900c535741f8
Adding config vars and restarting myapp... done, v2
GITHUB_TOKEN: 78a326b40bf6a7bfd80b0377445707523dfc4b299366942d19904fafe685afe6426d900c535741f8

# Returns all ENV
$ heroku config
GITHUB_TOKEN: 78a326b40bf6a7bfd80b0377445707523dfc4b299366942d19904fafe685afe6426d900c535741f8

# Get a single ENV
$ heroku config:get GITHUB_TOKEN
78a326b40bf6a7bfd80b0377445707523dfc4b299366942d19904fafe685afe6426d900c535741f8

# Unset an ENV
$ heroku config:unset GITHUB_TOKEN
Unsetting GITHUB_TOKEN and restarting myapp... done, v3
```

And if you're not using Heroku, you should try to make your experience [Heroku-like](https://devcenter.heroku.com/articles/config-vars).

## Conclusion

Manage environment variables is easier than ever with [dotenv][dotenv]. Just commit common `.env`, overrides in `.env.local` and you're good to go!

Happy Managing! :blush:

[12factor-app]: https://12factor.net/
[env-fetch]: https://ruby-doc.org/core-2.3.0/ENV.html#method-c-fetch
[store-config-in-env]: https://12factor.net/config
[dotenv]: https://github.com/bkeepers/dotenv
[install]: https://github.com/bkeepers/dotenv#installation
[mystery-guest]: https://robots.thoughtbot.com/mystery-guest
