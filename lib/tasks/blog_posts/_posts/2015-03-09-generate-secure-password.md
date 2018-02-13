---
layout: post
title: Generate Secure Password
date: 2015-03-09 14:41:01
description: Generate Secure Password by pwgen or 1password
tags: "macos", "tools", "security"
---

## [pwgen](https://github.com/jbernard/pwgen)

## Install on macOS

```
$ brew install pwgen
```

Add this function to `.bashrc` or `.zshrc`:

```bash
function pwdgen() {
  pwgen -Bs $1 1 | pbcopy | pbpaste | echo "Copied to clipboard!"
}
```

Source your `.bashrc` or `.zshrc`:

```
source ~/.zshrc
```

To generate a 8-char password:

```
$ pwdgen 8
Copied to clipboard!
```

To configure your generated password, see pwgen(1) man page:

```
$ man pwgen
```

Then edit the function in your shell startup file accordingly.

## [1Password](https://1password.com/)

Please refer to 1Password's offical download page for all platforms:

[1Password Download Page](https://1password.com/downloads/)

Linux you can use alternative software like:

- https://www.keepassx.org
- https://lastpass.com
- https://pwsafe.org

Secure your password!
