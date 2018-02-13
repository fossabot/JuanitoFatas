---
layout: post
title: "Active Loader"
date: 2016-06-12 16:26:37
description: "Introducing Active Loader - a RubyGem to load YAML, and JSON."
tags: "ruby", "rubygem"
---

I wrote a gem called ["Active Loader"](https://github.com/JuanitoFatas/active_loader) to load YAML / JSON either from local path / remote url / the content directly.

In some app I need fetch remote yaml and remote json, sometimes also need to read some json / yaml from local system. Why not combine them? This is the motivation.

What I learned:

- [How to alias a class method](https://github.com/JuanitoFatas/active_loader/blob/633766207ada1880ec6b41a46c105c56658c54db/lib/active_loader.rb#L15)
- [How to check if string is url](https://github.com/JuanitoFatas/active_loader/blob/633766207ada1880ec6b41a46c105c56658c54db/lib/active_loader/content_loader.rb#L30-L37)
- [How to check if string is path](https://github.com/JuanitoFatas/active_loader/blob/633766207ada1880ec6b41a46c105c56658c54db/lib/active_loader/content_loader.rb#L39-L41)
- [YAML.safe_load method](http://ruby-doc.org/stdlib-2.3.0/libdoc/psych/rdoc/Psych.html#method-c-safe_load)
- [A possible bug of YAML (psych)](https://github.com/JuanitoFatas/active_loader/blob/master/spec/integration_spec.rb#L12-L17)
- and lots of fun!

Do you make something useful (to you / to the public)?

Write a gem and Open Source it, it is fun! :wink:

And it is featured on [Ruby Weekly #302](http://rubyweekly.com/issues/302) :victory_hand::skin-tone-2::sparkling_heart:
