---
layout: post
title: "RubyGem Configuration Pattern"
date: 2015-05-19 09:15:35
description: "How to add support for gem users to configure gem's configurations."
tags: "ruby", "rubygem"
---

So your gem need to provide set of configurations for your user. It is very typical you put a Gem's config in an initializer in your Rails app:

```ruby
Yourgem.configure do |config|
  config.some_config = "foobarbaz"
end
```

But...How do we implement `Yougem.configure do |config|; ... end`?

```ruby
module Yourgem
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=(configuration)
    @configuration = configuration
  end

  def self.configure
    yield configuration
  end

  class Configuration
    attr_accessor :some_config

    def initialize
      @some_config = "foobarbaz"
    end
  end
end
```

Add more configs in `Configuration` class's `attr_accessor` and reference in your code:

```ruby
Yourgem.configuration.some_config
```

Then replace all hard-coded configurations in your gem.

With tests, of course:

```ruby
class YourgemConfigurationTest < Minitest::Test
  def teardown
    Yourgem.configuration = nil
    Yourgem.configure {}
  end

  def test_configuration_defaults
    assert_equal "foobarbaz", Yourgem.configuration.some_config
  end

  def test_configuration_asset_root
    Yourgem.configure do |config|
      config.some_config = "newconfig"
    end

    assert_equal "newconfig", Yourgem.configuration.some_config
  end
end
```

Note that you need to undo those configs in a tear down block.

Real life example see: https://github.com/jollygoodcode/twemoji/pull/15.

If you have Active Support as dependency, you can use `ActiveSupport::Configurable`.

Checkout a real life example which uses `ActiveSupport::Configurable`:

https://github.com/amatsuda/active_decorator/blob/master/lib/active_decorator/config.rb.

For a RSpec example, checkout thoughtbot's [Clearance](https://github.com/thoughtbot/clearance) gem.

Isn't this easy? Now you can add configuration easily for your gem users.
