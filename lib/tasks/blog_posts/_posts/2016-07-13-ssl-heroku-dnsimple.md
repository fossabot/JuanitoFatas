---
layout: post
title: Rails app on Heroku with SSL from DNSimple
date: 2016-07-12 18:00:00
description: Buy, prepare, and deploy an SSL certificate from DNSimple for your Heroku app.
tags: "rails", "web", "dns"
---

This tutorial will share how to add HTTPS (certificate via [DNSimple]) to your Rails app hosted on Heroku.

[dnsimple]: https://dnsimple.com

## 1. Buy / Renew the SSL certification from DNSimple

*Note you'll need to sign up a DNSimple account.*

- Buy a Single subdomain

  If you only need `example.com` / `www.example.com`.

- Buy a Wildcard certificate

  If you need `staging.example.com`, `subdomain.example.com`, `api.example.com` or any other subdomains.

- [Renew][renew]

  If you already got certificate and wants to renew.

Go to [DNSimple site to buy a single subdomain / wildcard domain certificate](https://dnsimple.com/ssl-certificates) and follow the instructions.

*This will cost you $20 (single subdomain) or $100 (wildcard) per year.*

[renew]: https://support.dnsimple.com/articles/renewing-ssl-certificates/

## 2. Get certificate files

After you bought certificate from DNSimple, [download your `.pem`, `.key` and `.crt` (if wildcard) files][download-cert-files].

We need these files to add to our Heroku app.

[download-cert-files]: https://support.dnsimple.com/articles/getting-started-ssl-certificates/#download

## 3. Enable Heroku SSL Endpoint addon

```
$ heroku addons:create ssl:endpoint
```

Put the files under your project root then run:

```
$ heroku certs:add *.{pem,crt,key}
Adding SSL Endpoint to example... done
example now served by example-1234.herokussl.com.
Certificate details:
...
```

Note the line with:

```
example now served by example-1234.herokussl.com.
```

This url: `example-1234.herokussl.com` is important.

**If your Heroku app is on Europe region, you will get url `*.herokuapp.com` instead of `*.herokussl.com`.**

You can also run:

```
$ heroku certs
Endpoint                    Common Name(s)             Expires          Trusted
--------------------  --------------------------  --------------------  -------
example.herokuapp.com  www.example.com, example.com  2017-07-07 23:59 UTC  True
```

to find out your SSL endpoint.

*This will cost you $20 per month.*

## 4. Config domains for Heroku

For single subdomain:

```
$ heroku domains:add www.example.com
$ heroku domains:add example.com
```

For wildcard subdomain:

```
$ heroku domains:add *.example.com
```

## 5. Add DNS records to DNSimple

Add these records to the DNS records:

For single subdomain:

```
ALIAS example.com  your SSL endpoint
CNAME www.example.com  your SSL endpoint
```

For wildcard subdomain:

```
ALIAS example.com  your SSL endpoint
CNAME *.example.com  your SSL endpoint
```

your SSL endpoint could be `*.herokussl.com` (US region) / `*.herokuapp.com` (Europe Region).

You can also use the one-click service provided by DNSimple:

- **If Heroku app is on US region**, use *Heroku SSL* one-click service
- **If Heroku app is on Europe region**, use *Heroku* one-click service

## 6. Rails app

Enable [`force_ssl`](http://api.rubyonrails.org/classes/ActionController/ForceSSL/ClassMethods.html#method-i-force_ssl) option for your production-like environment (staging, production):

```
# config/environments/production.rb or config/environments/staging.rb
config.force_ssl = true
config.action_controller.default_url_options = { host: "www.example.com" }
config.action_controller.asset_host = "www.example.com"
```

Deploy then congratulations :tada:, your app now served through secure connection!
