---
layout: post
title: Building A Simple Mocking Library in Ruby
date: 2015-08-20 02:00:00
description: Build a mocking library from scratch!
tags: "ruby", "testing"
---

This tutorial is based on [Andy Lindeman](http://andylindeman.com)'s awesome talk — [Building a Mocking Library](https://www.youtube.com/watch?v=2aYdtS7FZJA) presented at [Ancient City Ruby 2013](http://confreaks.tv/events/acr2013). This is not a direct transcript of the video, but the code presented is almost the same (with minimal changes).

In his talk, Andy showed us how we can build a Mocking library for Minitest with just basic knowledge of Ruby and I felt that it's actually a great way to learn Ruby! So I decided to document the talk in writing and share it up here on the blog so that we can all learn together.

## Goal

We are going to implement a simple Mocking library for [Minitest](https://github.com/seattlerb/minitest).

Given an object:

```ruby
# Test double
object = Object.new
```

We should be able to stub a method on this object and it will return our stubbed value:

```ruby
# Stub
allow(object).to receive(:full?).and_return(true)
object.full? # => true
```

We should be able to mock an object (mock will verify if `removed` was ever called, while stub does not do that check):

```ruby
# Mock
item_id = 1234
assume(object).to receive(:remove).with(item_id)
```

Why don't we use `expect(w).to receive(:remove).with(item_id)` here, similar to RSpec? That's because Minitest has an [`#expect` method](https://github.com/seattlerb/minitest/blob/6f53d4d986ce0acb1ba7e38ba1f2d010102ce8bf/lib/minitest/mock.rb#L71-L82), so let's avoid redefining it.

## Design

We will have two main classes - `StubTarget` and `ExpectationDefinition`.

Remember our Goal? In order to be able to do this:

```ruby
allow(w).to receive(:full?).and_return(true)
```

We'll break them up as follows using our two main classes:

```ruby
allow(w).to      receive(:full?).and_return(true)
^^^^^^^^^^^      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#<StubTarget>    #<ExpectationDefinition>
```

## Enough Ruby that You Need to Know

### Method Dispatch

How does Ruby find methods? It climbs up the ancestors chain! When you invoke `to_s` on object `object`, Ruby asks `object`...

**Ruby**: _Hey, do you have `to_s` method?_
**object**: _Yup. I do._
**Ruby**: _Awesome! Call it!_
**object**: _(invoking `to_s`)_

Then it returns the result of `object.to_s` which is `"#<Object:0x007fc0223b8280>"`:

```ruby
> object = Object.new
=> #<Object:0x007fc0223b8280>

> object.to_s
=> "#<Object:0x007fc0223b8280>"
```

[More on Method Dispatch](https://blog.jcoglan.com/2013/05/08/how-ruby-method-dispatch-works)

### Ancestors Chain

If Ruby can't find the method you want to call, it will climb up the ancestors chain, till it finds a class that responds to the message, otherwise it eventually throws a `NoMethodError` exception.

```ruby
object.class.ancestors
=> [Object, Kernel, BasicObject] # (searching from left to right)
```

### Define a Method for a Specific Object

Ruby has a singleton class for every object and you can define a method in the singleton class.

The singleton class might be not visible in the ancestors chain above, but it's there.

#### Singleton Class

The "Singleton Class" is easily confused with the [Singleton](http://c2.com/cgi/wiki?SingletonPattern) design pattern.

In fact, singleton class is an anonymous class attached to a specific object. Best illustrated with an example:

```ruby
object = Object.new

def object.hello_world
  "Hello, World!"
end

object.hello_world # => "Hello, World!"

another_object = Object.new

object.hello_world # => NoMethodError (2)
```

In the example above, we are adding a `hello_world` method to the `object`. But the `hello_world` method wasn't added to the `Object` class (See (2) above).

As you can see, Ruby insert the `hello_world` method into `object`'s singleton class!

[More on Singleton Class](http://www.devalot.com/articles/2008/09/ruby-singleton)

##### `define_singleton_method`

Another way to define a method for singleton class, is to use [`define_singleton_method(symbol, method_object)`](http://ruby-doc.org/core-2.2.2/Object.html#method-i-define_singleton_method).

The example above could be re-written as follows:

```ruby
> object = Object.new
=> #<Object:0x007fc0223b8280>

> object.singleton_class
=> #<Class:#<Object:0x007fc0223b8280>>

> object.define_singleton_method(:hello_world) { "Hello, World!" }
```

The `define_singleton_method` accepts a method name and a [`Method` object](http://ruby-doc.org/core-2.2.2/Method.html). Think of a Method object as similar to a `proc` or `lambda`.

That's enough Ruby that you need to know. Yup. That's all!

## Building a Mock Object Library

Since this is a Mocking _library_, let's make it a gem!

### Your Mocking Gem

Let's gemify our mocking library. You can name it using this pattern: `yourname_mock`. My name is Juanito and so I will call it `juanito_mock`, and we'll also use [`bundle gem`](http://bundler.io/v1.10/bundle_gem.html) command provided by [Bundler](http://bundler.io) to create a skeleton of our gem:

```
$ bundle gem juanito_mock && cd juanito_mock
```

Note that Bundler may prompt you to choose which test library you want to use, type `minitest` and hit <kbd>ENTER</kbd>.

```
Creating gem 'juanito_mock'...
MIT License enabled in config
Do you want to generate tests with your gem?
Type 'rspec' or 'minitest' to generate those test files now and in the future. rspec/minitest/(none):
```

If your generated skeleton gem has no tests or is generated with `spec` folder, edit `~/.bundle/config` file, add this line (or modify):

```
BUNDLE_GEM__TEST: minitest
```

Remove the generated folder and repeat it from the top again.

The structure of the gem should look like this:

```
├── Gemfile
├── LICENSE.txt
├── README.md
├── Rakefile
├── bin
│   ├── console
│   └── setup
├── juanito_mock.gemspec
├── lib
│   ├── juanito_mock
│   │   └── version.rb
│   └── juanito_mock.rb
└── test
    ├── juanito_mock_test.rb
    └── test_helper.rb
```

#### Why Minitest?

Since we are implementing a RSpec-like mocking syntax, we don't want to use RSpec here so as to avoid confusions and conflicts with the original RSpec mocking library. Hence, we are going to use Minitest here to test our Mocking library.

By the way, the correct spelling of Minitest is _Minitest_, not _MiniTest_.

> Renamed MiniTest to Minitest. Your pinkies will thank me.
> [Minitest 5.0.0 History](https://github.com/seattlerb/minitest/blob/master/History.rdoc#500--2013-05-10)

### Setup Minitest

First lock Minitest to `5.8.0` in gemspec's [development dependency](http://guides.rubygems.org/specification-reference/#add_development_dependency) in order to use it in development:

```ruby
spec.add_development_dependency "minitest", "5.8.0"
```

Latest version of Minitest is `5.8.0` as of 16th Aug 2015.

Add these lines to `test/test_helper.rb`:

```ruby
require "minitest/spec"
require "minitest/autorun"
```

Reorder and your `test/test_helper.rb` should look like this:

```ruby
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "minitest/spec" # simple and clean spec system
require "minitest/autorun" # easy and explicit way to run all your tests
require "juanito_mock"
```

Note on quotes of string. [_Just Use double-quoted strings_](https://viget.com/extend/just-use-double-quoted-ruby-strings)

We use [Minitest/Spec](http://docs.seattlerb.org/minitest/Minitest/Spec/DSL.html) syntax to write our tests and `require "minitest/autorun"` to easily run all our tests.

Next, delete the generated tests in `test/juanito_mock_test.rb` and update it with DSL:

```ruby
require "test_helper"

describe JuanitoMock do

end
```

Now if you run `rake`, you should have a working test suite:

```
$ rake
Run options: --seed 55155

# Running:


Finished in 0.000783s, 0.0000 runs/s, 0.0000 assertions/s.

0 runs, 0 assertions, 0 failures, 0 errors, 0 skips
```

Now let's write our first test!

### Implementation of Stub

Create a test case by using `it` followed by a descriptive description string, and a block of code:

```ruby
describe JuanitoMock do
  it "allows an object to receive a message and returns a value" do
    warehouse = Object.new

    allow(warehouse).to receive(:full?).and_return(true)

    warehouse.full?.must_equal true
  end
end
```

Let's walk through the code..

```ruby
warehouse = Object.new
```

Firstly, we create a new instance of `Object` and assign it to a variable `warehouse`.

```ruby
allow(warehouse).to receive(:full?).and_return(true)
```

Then, we create a stub that will receive the method `full?` and return the result `true`.

```ruby
warehouse.full?.must_equal true
```

Finally, we verify our stub is working by using [must_equal](http://docs.seattlerb.org/minitest/Minitest/Expectations.html#method-i-must_equal).

Sidenote: See the blank lines in our test? These blank lines are very important to distinguish different phases of the test.

[More on Four Phase Test](http://xunitpatterns.com/Four%20Phase%20Test.html)

#### How to Run Tests

First, let's take a look at `Rakefile`:

```ruby
require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test
```

`require "rake/testtask"` included in a file with a rake task defined (`rake test`) that can run our tests easily via [rake](https://github.com/ruby/rake), see [Rake::TestTask](http://ruby-doc.org/stdlib-2.2.2/libdoc/rake/rdoc/Rake/TestTask.html) for more information.

You can see a full list of rake tasks available by typing `rake -T` in your terminal:

```
$ rake -T
rake build          # Build juanito_mock-0.1.0.gem into the pkg directory
rake install        # Build and install juanito_mock-0.1.0.gem into system ...
rake install:local  # Build and install juanito_mock-0.1.0.gem into system ...
rake release        # Create tag v0.1.0 and build and push juanito_mock-0.1...
rake test           # Run tests
```

The `build`, `install`, `install:local`, and `release` tasks are provided by Bundler. See [bundler/bundler lib/bundler/gem_helper.rb](https://github.com/bundler/bundler/blob/a490f6a1892e6033ed0f1a12a0c8c3e188518e8d/lib/bundler/gem_helper.rb#L37-L68)

But you also see that `rake test` is available for use.

To make it even simple to run your tests, the `Rakefile` has this `task :default => :test` which basically maps the default rake task to running tests.

This means that you can just type `rake` instead of `rake test` to run all your tests.

Let's run it:

```
$ rake
Run options: --seed 49489

# Running:

E

Finished in 0.000963s, 1038.1963 runs/s, 0.0000 assertions/s.

  1) Error:
JuanitoMock#test_0001_allows an object to receive a message and returns a value:
NoMethodError: undefined method `allow' for #<#<Class:0x007fe04516bf70>:0x007fe045d001d8>
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:7:in `block (2 levels) in <top (required)>'

1 runs, 0 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

Yay! Our first failing test, read the error carefully to find out what to do next:

```
undefined method `allow' for #<#<Class:0x007fe04516bf70>:0x007fe045d001d8>
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:7:in `block (2 levels) in <top (required)>'
```

It even tells you which line to fix the code:

```
test/juanito_mock_test.rb:7
```

`:7` means line 7 from the file `test/juanito_mock_test.rb`.

#### Add DSL to Minitest

Let's proceed to fix the failing test.

From Minitest README, we know every test in Minitest is a subclass of [`Minitest::Test`](https://github.com/seattlerb/minitest/blob/master/lib/minitest/test.rb):

To add method `allow` to `Minitest::Test`, all we have to do is to create a module `TestExtensions` and include it in the `Minitest::Test` class:

```ruby
require "juanito_mock/version"

module JuanitoMock
  module TestExtensions
    def allow
    end
  end
end

class Minitest::Test
  include JuanitoMock::TestExtensions
end
```

Let's run our test:

```
$ rake
Run options: --seed 41300

# Running:

E

Finished in 0.001002s, 997.6067 runs/s, 0.0000 assertions/s.

  1) Error:
JuanitoMock#test_0001_allows an object to receive a message and returns a value:
ArgumentError: wrong number of arguments (1 for 0)
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:5:in `allow'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'

1 runs, 0 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

Nice! Now we get a different error:

```
ArgumentError: wrong number of arguments (1 for 0)
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:5:in `allow'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'
```

The error occurs because we are calling `allow` like so `allow(warehouse)` in our code, which means we are passing in an argument `warehouse` which our allow method doesn't accept yet.

```ruby
allow(warehouse).to receive(:full?).and_return(true)
```

Let's fix this by modifying our `allow` method to accept an argument `obj`. Then, we'll construct an instance of `StubTarget` with the argument, as described in our [design](#design):

```ruby
require "juanito_mock/version"

module JuanitoMock
  module TestExtensions
    def allow(obj)
      StubTarget.new(obj)
    end
  end
end

class Minitest::Test
  include JuanitoMock::TestExtensions
end
```

Now run the test again:

```
$ rake
Run options: --seed 7548

# Running:

E

Finished in 0.000915s, 1092.3434 runs/s, 0.0000 assertions/s.

  1) Error:
JuanitoMock#test_0001_allows an object to receive a message and returns a value:
NameError: uninitialized constant JuanitoMock::TestExtensions::StubTarget
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:6:in `allow'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'

1 runs, 0 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

Another error this time:

```
NameError: uninitialized constant JuanitoMock::TestExtensions::StubTarget
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:6:in `allow'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'
```

Ruby is now complaining that it can't find the constant `JuanitoMock::TestExtensions::StubTarget`. Of course! That's because we haven't define `StubTarget` class yet, so let's define it:

```ruby
module JuanitoMock
  class StubTarget
    def initialize(obj)
      @obj = obj
    end
  end

  module TestExtensions
    def allow(obj)
      StubTarget.new(obj)
    end
  end
end

class Minitest::Test
  include JuanitoMock::TestExtensions
end
```

For a start, we will just save the `obj` in an instance variable.

Now run the test again:

```
$ rake
Run options: --seed 25153

# Running:

E

Finished in 0.001059s, 944.4913 runs/s, 0.0000 assertions/s.

  1) Error:
JuanitoMock#test_0001_allows an object to receive a message and returns a value:
NoMethodError: undefined method `receive' for #<#<Class:0x007fe080b5d430>:0x007fe081057058>
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'

1 runs, 0 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

What? Another error. This doesn't seem like it's ending soon. But you should actually rejoice, because we now have a different error, and that means we are progressing!

```
NoMethodError: undefined method `receive' for #<#<Class:0x007fe080b5d430>:0x007fe081057058>
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'
```

This time it's ranting about another missing method `receive`. Hmm what about `to`? Why didn't it complain about a missing method `to`?

That's because Ruby always tries to evaluate the right-hand side first, and so it's going to process `receive` first before it gets to `to`. Dont' worry, you'll see an error for `to` later.

Let's define a `receive` method in `TestExtensions` module which accepts a message:

```ruby
require "juanito_mock/version"

module JuanitoMock
  class StubTarget
    ...
  end

  module TestExtensions
    def allow(obj)
      ...
    end

    def receive(message)
      ExpectationDefinition.new(message)
    end
  end
end
```

As described in [design section](#design), `receive` will return a `ExpectationDefinition` instance.

Now run the test again:

```
$ rake
Run options: --seed 27383

# Running:

E

Finished in 0.001145s, 873.0986 runs/s, 0.0000 assertions/s.

  1) Error:
JuanitoMock#test_0001_allows an object to receive a message and returns a value:
NameError: uninitialized constant JuanitoMock::TestExtensions::ExpectationDefinition
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:16:in `receive'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'

1 runs, 0 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

You probably already expected it and now Ruby complains that it cannot find `ExpectationDefinition`:

```
NameError: uninitialized constant JuanitoMock::TestExtensions::ExpectationDefinition
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:16:in `receive'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'
```

Let's go ahead and define it, keeping `ExpectationDefinition` simple, such that it only accepts an argument and stores it in an instance variable.

```ruby
module JuanitoMock
  class StubTarget
    ...
  end

  class ExpectationDefinition
    def initialize(message)
      @message = message
    end
  end

  module TestExtensions
    ...
  end
end
```

Now run the test again:

```
$ rake
Run options: --seed 47423

# Running:

E

Finished in 0.001005s, 995.4657 runs/s, 0.0000 assertions/s.

  1) Error:
JuanitoMock#test_0001_allows an object to receive a message and returns a value:
NoMethodError: undefined method `and_return' for #<JuanitoMock::ExpectationDefinition:0x007fe072f6a798>
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'

1 runs, 0 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

Now Ruby cannot find the `and_return` method
(poor Ruby, thanks for doing so much work for us :cry:):

```
NoMethodError: undefined method `and_return' for #<JuanitoMock::ExpectationDefinition:0x007fe072f6a798>
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'
```

Looking at the error, it's actually telling us that it cannot find the `and_return` method on `ExpectationDefinition`, so let's define it there:

```ruby
require "juanito_mock/version"

module JuanitoMock
  class StubTarget
    ...
  end

  class ExpectationDefinition
    def initialize(message)
      @message = message
    end

    def and_return(return_value)
      @return_value = return_value
      self
    end
  end

  module TestExtensions
    ...
  end
end
```

This new method `and_return` is interesting and contains the secret to enabling method chaining.

Do you know what it is?

Yes. The method is returning `self`!

```ruby
def and_return(return_value)
  @return_value = return_value
  self
end
```

That's the magic to building a chaining interface for your objects! All you have to do is to build up objects and return `self`!

Now let's run our test again:

```
$ rake
Run options: --seed 11338

# Running:

E

Finished in 0.001084s, 922.9213 runs/s, 0.0000 assertions/s.

  1) Error:
JuanitoMock#test_0001_allows an object to receive a message and returns a value:
NoMethodError: undefined method `to' for #<JuanitoMock::StubTarget:0x007ff48a516590>
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'

1 runs, 0 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

Yes! Now we see the error for undefined method `to` on `StubTarget` class, and so let's define the `to` method on `StubTarget` class according to our design:

```ruby
allow(warehouse).to receive(:full?).and_return(true)
^^^^^^^^^^^^^^^^    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    StubTarget            ExpectationDefinition
```

where the `to` method accepts an `ExpectationDefinition` object as argument.

```ruby
module JuanitoMock
  class StubTarget
    def initialize(obj)
      @obj = obj
    end

    def to(definition)
    end
  end

  class ExpectationDefinition
    ...
  end

  module TestExtensions
    ...
  end
end
```

Now let's run our test again:

```
$ rake
Run options: --seed 31564

# Running:

E

Finished in 0.001092s, 915.9027 runs/s, 0.0000 assertions/s.

  1) Error:
JuanitoMock#test_0001_allows an object to receive a message and returns a value:
NoMethodError: undefined method `full?' for #<Object:0x007f8fcc47dc28>
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:11:in `block (2 levels) in <top (required)>'

1 runs, 0 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

Reading our next failure, the error guides us to define a `full?` method on the object:

```
NoMethodError: undefined method `full?' for #<Object:0x007f8fcc47dc28>
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:11:in `block (2 levels) in <top (required)>'
```

Let's use the aforementioned `define_singleton_method` magic to define the `full?` method, and which returns the expected value of `true` as specified in our test:

```ruby
module JuanitoMock
  class StubTarget
    ...

    def to(definition)
      @obj.define_singleton_method definition.message do
        definition.return_value
      end
    end
  end

  class ExpectationDefinition
    ...
  end

  module TestExtensions
    ...
  end
end
```

Now run the tests again:

```
$ rake
Run options: --seed 14082

# Running:

E

Finished in 0.001091s, 916.4954 runs/s, 0.0000 assertions/s.

  1) Error:
JuanitoMock#test_0001_allows an object to receive a message and returns a value:
NoMethodError: undefined method `message' for #<JuanitoMock::ExpectationDefinition:0x007ff31d8ae220>
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:10:in `to'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'

1 runs, 0 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

This time Ruby cannot find `message` on `ExpectationDefinition`:

```
NoMethodError: undefined method `message' for #<JuanitoMock::ExpectationDefinition:0x007ff31d8ae220>
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:10:in `to'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'
```

Keeping it simple, we expose `message` and `return_value` in `ExpectationDefinition` class with `attr_reader`:

```ruby
module JuanitoMock
  ...

  class ExpectationDefinition
    attr_reader :message, :return_value

    def initialize(message)
      @message = message
    end

    ...
  end

  ...
end
```

Now run this test again:

```
$ rake
Run options: --seed 46498

# Running:

.

Finished in 0.000975s, 1025.2078 runs/s, 1025.2078 assertions/s.

1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
```

Our first passing test!

![WOO-HOO!](https://cloud.githubusercontent.com/assets/1000669/9292339/2470c960-4425-11e5-8ac2-c04ee77dc437.jpg)

```ruby
allow(warehouse).to receive(:full?).and_return(true)
```

This line in the test is actually passing! Just with 42 lines of code in a relatively short amount of time!

Let's take a step back to see what we have done so far. Basically, we started to build our Mocking library by writing a test - a failing test. Then we write some code to error that was thrown, and some more code to fix the next error that was thrown and so on and so forth. And finally, through our persistence, we got the test to pass!

This practice of writing software is what we call Test Driven Development (TDD), where we go from red (failing test), to green (passing test) and moving on to refactor. This is a practice that a lot of software engineers embrace, and it's one which we have found immense benefits when doing it consistently.

## The Edge of Mocking

![edge-of-tomorrow-13](https://cloud.githubusercontent.com/assets/1000669/9292105/74ed97c2-4418-11e5-9f67-67d951189be1.jpg)

Are we done already? Not quite!

In our current code, we defined the `full?`method on the object when the test starts, but we didn't do anything to reset our change after the test finishes, and that's actually not so good, because it might affect other tests. So, we should reset the state and unset the `full?` method that we have "stubbed".

Let's write another test for this:

```ruby
  it "removes stubbed method after tests finished" do
    warehouse = Object.new

    allow(warehouse).to receive(:full?).and_return(true)

    JuanitoMock.reset

    assert_raises(NoMethodError) { warehouse.full? }
  end
```


_I intentionally prefix each line with two spaces to make it copy-paste friendly, but I strongly encourage you to type on your own._


In the above test, we invoke `JuanitoMock.reset` to clear/undo all changes to the code, and we verify this by using [`assert_raises`](http://docs.seattlerb.org/minitest/Minitest/Assertions.html#method-i-assert_raises) where we test that an exception is raised
when `full?` is invoked.

At this point, this is how your test file should look like:

```ruby
require "test_helper"

describe JuanitoMock do
  it "allows an object to receive a message and returns a value" do
    warehouse = Object.new

    allow(warehouse).to receive(:full?).and_return(true)

    warehouse.full?.must_equal true
  end

  it "removes stubbed method after tests finished" do
    warehouse = Object.new

    allow(warehouse).to receive(:full?).and_return(true)

    JuanitoMock.reset

    assert_raises(NoMethodError) { warehouse.full? }
  end
end
```

Once again, we run the test to find out what to do next:

```
$ rake
Run options: --seed 30441

# Running:

.E

Finished in 0.001152s, 1736.7443 runs/s, 868.3721 assertions/s.

  1) Error:
JuanitoMock#test_0002_removes stubbed method after tests finished:
NoMethodError: undefined method `reset' for JuanitoMock:Module
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:17:in `block (2 levels) in <top (required)>'

2 runs, 1 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

Oops. Did you expect that - undefined method `reset` for `JuanitoMock:Module`?

Let's write this method! Edit `lib/juanito_mock.rb` and add this module-level method:

```ruby
module JuanitoMock
  ...

  module TestExtensions
    ...
  end

  def self.reset
  end
end
```

What do we do next? What should we write in the method? Run the test and let that help us!

```
$ rake
Run options: --seed 22585

# Running:

.F

Finished in 0.001207s, 1657.1930 runs/s, 1657.1930 assertions/s.

  1) Failure:
JuanitoMock#test_0002_removes stubbed method after tests finished [/Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:19]:
NoMethodError expected but nothing was raised.

2 runs, 2 assertions, 1 failures, 0 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

`NoMethodError expected but nothing was raised.`. Yup. That's what I expected, too.

How can we undefine the method `full?` that we have stubbed on the object? As we had defined the method `full?` in the object's singleton class, there is actually no reference to it and so we don't know how to undefine it, at least for now...

Let's park that for now, and do something else instead (which would help us later).

Let's improve the code!

We are going to make some changes to our code without losing the any of our current functionality.

Let's start by wrapping the define method step into a class, a delegate class and name it: `Stubber`. Put `Stubber` below `StubTarget` and above the `ExpectationDefinition`:

```ruby
module JuanitoMock
  class StubTarget
    ...
  end

  class Stubber
    def initialize(obj)
      @obj = obj
    end

    def stub(definition)
    end
  end

  class ExpectationDefinition
    ...
  end
end
```

Then, move the implementation of `StubTarget#to` to `Stubber#stub`:

```ruby
module JuanitoMock
  class StubTarget
    ...
  end

  class Stubber
    def initialize(obj)
      @obj = obj
    end

    def stub(definition)
      @obj.define_singleton_method definition.message do
        definition.return_value
      end
    end
  end

  class ExpectationDefinition
    ...
  end
end
```

In `StubTarget#to`, we delegate the job to `Stubber#stub`:

```ruby
module JuanitoMock
  class StubTarget
    ...

    def to(definition)
      Stubber.new(@obj).stub(definition)
    end
  end

  ...
end
```

Nice [refactoring](http://c2.com/cgi/wiki?WhatIsRefactoring)! This is an essential step in the TDD practice, and what we just did was basically to improve our code without modifying the current feature set of our code. We can verify this by running our tests which would prove that the first test is green, while the second test is still red:

```
$ rake
Run options: --seed 23169

# Running:

.F

Finished in 0.001183s, 1691.2146 runs/s, 1691.2146 assertions/s.

  1) Failure:
JuanitoMock#test_0002_removes stubbed method after tests finished [/Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:19]:
NoMethodError expected but nothing was raised.

2 runs, 2 assertions, 1 failures, 0 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

Let's get back to fixing the error.

Let's store what we stubbed in an array called `@definitions`, in `Stubber#stub`:

```ruby
module JuanitoMock
  ...

  class Stubber
    def initialize(obj)
      @obj = obj
      @definitions = []
    end

    def stub(definition)
      @definitions << definition

      @obj.define_singleton_method definition.message do
        definition.return_value
      end
    end
  end

  ...
end
```

However, having the `@definitions` array is not enough because the `Stubber` instance in:

```ruby
    def to(definition)
      Stubber.new(@obj).stub(definition)
    end
```

immediately goes out of scope and gets garbage collected, and so we still do not have a list of all methods that were stubbed.

Hence we need to be able to save the `Stubber` instance(s) by using a `Stubber.for_object` class-level method:

```ruby
module JuanitoMock
  class StubTarget
    def initialize(obj)
      @obj = obj
    end

    def to(definition)
      Stubber.for_object(@obj).stub(definition)
    end
  end

  ...
end
```

Now run the test again:

```
$ rake
Run options: --seed 37100

# Running:

EE

Finished in 0.001317s, 1518.4864 runs/s, 0.0000 assertions/s.

  1) Error:
JuanitoMock#test_0002_removes stubbed method after tests finished:
NoMethodError: undefined method `for_object' for JuanitoMock::Stubber:Class
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:10:in `to'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:15:in `block (2 levels) in <top (required)>'


  2) Error:
JuanitoMock#test_0001_allows an object to receive a message and returns a value:
NoMethodError: undefined method `for_object' for JuanitoMock::Stubber:Class
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:10:in `to'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:7:in `block (2 levels) in <top (required)>'

2 runs, 0 assertions, 0 failures, 2 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

The next error to fix is to define `for_object` on `Stubber` class:

```
  NoMethodError: undefined method `for_object' for JuanitoMock::Stubber:Class
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:10:in `to'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:7:in `block (2 levels)
```

This `Stubber.for_object` method is a custom initializer for the `Stubber` class that will not only create `Stubber` instances, but also store them in a lazily-initialized hash, with its [`object_id`](http://ruby-doc.org/core-2.2.2/Object.html#method-i-object_id) as key:

```ruby
module JuanitoMock
  class Stubber
    def self.stubbers
      @stubbers ||= {}
    end

    def self.for_object(obj)
      stubbers[obj.__id__] ||= Stubber.new(obj)
    end

    ...
  end
end
```

But are we making progress for `JuanitoMock.reset`? Hmm.. Let's run the tests first.

```
$ rake
Run options: --seed 4701

# Running:

.F

Finished in 0.001117s, 1789.8854 runs/s, 1789.8854 assertions/s.

  1) Failure:
JuanitoMock#test_0002_removes stubbed method after tests finished [/Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:19]:
NoMethodError expected but nothing was raised.

2 runs, 2 assertions, 1 failures, 0 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

The failure is still the same as before, but we are actually making a progress.

Given that all the stubbed methods are now stored in the `Stubber` class, it would be great if we have one single method in `Stubber` that can help us. Thinking along that line of thought, let's have a `Stubber.reset` method that does exactly that, and then it would be trivial for `JuanitoMock.reset` to invoke it!

Let's try to implement the logic for `Stubber.reset` that [we wish we have](http://c2.com/cgi/wiki?WishfulThinking).

`stubbers` currently is a hash that looks like this:

```ruby
{
  70173643198180 => #<Stubber instance>
}
```

It is a one-to-one object id mapping to a `Stubber` instance. We would first want each instance to unstub the method that we stub earlier. The intent is still similar, so each instance should have its own `reset` method that we can call. Also, the `reset` method should empty the hash after we are done with it.
Cool! Ruby has a [`clear`](http://ruby-doc.org/core-2.2.2/Hash.html#method-i-clear) method that we can use.

```ruby
module JuanitoMock
  ...

  class Stubber
    ...

    def self.for_object(obj)
      ...
    end

    def self.reset
      stubbers.each_value(&:reset)
      stubbers.clear
    end

    ...
  end

  ...

  module TestExtensions
    ...
  end

  def self.reset
    Stubber.reset
  end
end
```

Run the tests again:

```
$ rake
Run options: --seed 11282

# Running:

.E

Finished in 0.001142s, 1751.6509 runs/s, 875.8255 assertions/s.

  1) Error:
JuanitoMock#test_0002_removes stubbed method after tests finished:
NoMethodError: undefined method `reset' for #<JuanitoMock::Stubber:0x007f9a85c7bf38>
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:24:in `each_value'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:24:in `reset'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:66:in `reset'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:17:in `block (2 levels) in <top (required)>'

2 runs, 1 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

Now we have an undefined method `reset` for `#<JuanitoMock::Stubber:0x007f9a85c7bf38>` - a `Stubber` instance:

```
JuanitoMock#test_0002_removes stubbed method after tests finished:
NoMethodError: undefined method `reset' for #<JuanitoMock::Stubber:0x007f9a85c7bf38>
```

Let's implement `Stubber#reset`. In `Stubber#reset`, what we need to do is to undefine/unstub the method we have defined/stubbed earlier.

In Ruby, we can use [remove_method](http://ruby-doc.org/core-2.2.0/Module.html#method-i-remove_method) with some [class_eval](http://ruby-doc.org/core-2.2.0/Module.html#method-i-class_eval) craziness to achieve this:

```ruby
module JuanitoMock
  ...

  class Stubber
    ...

    def stub(definition)
      ...
    end

    def reset
      @definitions.each do |definition|
        @obj.singleton_class.class_eval do
          remove_method(definition.message) if method_defined?(definition.message)
        end
      end
    end
  end

  ...
end
```

We avoid the `NoMethodError` exception by checking [method_defined?](http://ruby-doc.org/core-2.2.0/Module.html#method-i-method_defined-3F) on `definition.message`.

Now if you are brave enough to run the tests:

```
$ rake
Run options: --seed 55448

# Running:

..

Finished in 0.001233s, 1622.4943 runs/s, 1622.4943 assertions/s.

2 runs, 2 assertions, 0 failures, 0 errors, 0 skips
```

You shall see all our tests passed! All green! Yay!!!

![gatsby-screenshot2-e1397167545470](https://cloud.githubusercontent.com/assets/1000669/9292404/a67cd918-4429-11e5-8258-b4cc8b0e114e.png)

All tests passed, old sport! Can we live happily ever after now? Hmm...

## Blindly Removing Methods

Till now, we have covered the cases of stubbing and unstubbing. But there's actually a third case to consider!

What if, at the very beginning, there was already a `full?` method defined? We would have "killed" or "replaced" the original method unknowingly.

Let's write another test to describe this case:

```ruby
  it "preserves methods that originally existed" do
    warehouse = Object.new
    def warehouse.full?; false; end # defining methods on Ruby singleton class

    allow(warehouse).to receive(:full?).and_return(true)

    JuanitoMock.reset

    warehouse.full?.must_equal false
  end
```

Run the tests:

```
$ rake
Run options: --seed 4474

# Running:

.E.

Finished in 0.001266s, 2369.2790 runs/s, 1579.5193 assertions/s.

  1) Error:
JuanitoMock#test_0003_preserves methods that are originally existed:
NoMethodError: undefined method `full?' for #<Object:0x007fcdcd4d3b70>
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:29:in `block (2 levels) in <top (required)>'

3 runs, 2 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

We have a failure on our new test!

What happened was that our stub `allow(warehouse).to receive(:full?).and_return(true)` replaced the original method, and when we called `JuanitoMock.reset`, it only removed the stub but didn't bring back the original implementation for `full?`.

Hence the `NoMethodError` exception is expected, because the method's basically gone!

This is not ok. Let's fix that. But first let's take a look at `Stubber#stub` method:

```ruby
class Stubber
  ...

  def stub(definition)
    @definitions << definition

    # preserve original method if already exists

    @obj.define_singleton_method definition.message do
      definition.return_value
    end
  end

  ...
end
```

In our current implementation of `Stubber#stub`, we didn't check if the object already has the method or not and we just simply (re)defined the singleton method.

We should preserve the original method if it already exists like so:

```ruby
  class Stubber
    ...

    def stub(definition)
      @definitions << definition

      if @obj.singleton_class.method_defined?(definition.message)
        @preserved_methods <<
          @obj.singleton_class.instance_method(definition.message)
      end

      @obj.define_singleton_method definition.message do
        definition.return_value
      end
    end

    ...
  end
```

Let's walk through what we just did:

```ruby
@obj.singleton_class.instance_method(definition.message)
```

The magic comes from the use of [Module#instance_method](http://ruby-doc.org/core-2.2.0/Module.html#method-i-instance_method) which will return a method object of given name from the singleton class.

Think of this method object as a `proc` or `lambda` which we then we store in a `@preserved_methods` array:

```ruby
  class Stubber
    ...

    def initialize(obj)
      @obj = obj
      @definitions = []
      @preserved_methods = []
    end

    ...
  end
```

Preserving the orignal method is only one part of the solution.

When we do a `Stubber#reset`, we actually want to reinstate and redefine these saved preserved methods:

```ruby
  class Stubber
    ...

    def reset
      ...

      @preserved_methods.reverse_each do |method|
        @obj.define_singleton_method(method.name, method)
      end
    end
  end
```

We use `reverse_each` here because we need to preserve the original order of the methods. You can write a test here too to see the importance of using `reverse_each` but we'll leave it as an exercise!

P.S. Did you know [reverse_each is more efficient than reverse.each?](https://github.com/JuanitoFatas/fast-ruby#enumerablereverseeach-vs-enumerablereverse_each-code)

In `Stubber#stub`, we used `obj.define_singleton_method` with a block, but it also pairs really well with method objects that we are dealing with in the `@preserved_methods` array.

Every method object [Method#instance_method](http://ruby-doc.org/core-2.2.0/Module.html#method-i-instance_method) has a [Method#name](http://ruby-doc.org/core-2.2.0/Method.html#method-i-name) method that returns the name of the method. We can simply redefine the method by calling `define_singleton_method` with the method name and the method object itself.

Run the tests again and we should have three passing tests:

```
$ rake
Run options: --seed 63328

# Running:

...

Finished in 0.001223s, 2453.9275 runs/s, 2453.9275 assertions/s.

3 runs, 3 assertions, 0 failures, 0 errors, 0 skips
```

This also means we have successfully restored the original methods after the tests!

Congrats on getting so far, but we are not quite done. By now we have only implemented `stub` (and unstub), and next we are going to implement `mock` - which is an expectation that a message will be received.

## [To Mock a Mockingbird](https://en.wikipedia.org/wiki/To_Mock_a_Mockingbird)

[![mimus_polyglottos1](https://cloud.githubusercontent.com/assets/1000669/9292099/1729a2c0-4418-11e5-9d8a-9eb9471e6532.jpg)](https://en.wikipedia.org/wiki/Mockingbird)

Let's start with a new failing test as usual:

```ruby
  it "expects that a message will be received" do
    warehouse = Object.new

    assume(warehouse).to receive(:empty)

    # warehouse.empty not called!

    assert_raises(JuanitoMock::ExpectationNotSatisfied) do
      JuanitoMock.reset
    end
  end
```

In our test, `assume(warehouse).to receive(:empty)` expects that `warehouse.empty` will be invoked. However we are not actually going to call the `empty` method and so, we assert that a custom exception `JuanitoMock::ExpectationNotSatisfied` will be raised when we call `JuanitoMock.reset` which loops and verfies each expectation.

Let's run the test:

```
$ rake
Run options: --seed 30442

# Running:

..E.

Finished in 0.001308s, 3058.4267 runs/s, 2293.8200 assertions/s.

  1) Error:
JuanitoMock#test_0004_expects that a message will be received:
NoMethodError: undefined method `assume' for #<#<Class:0x007facec071a20>:0x007facecbea5a0>
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:35:in `block (2 levels) in <top (required)>'

4 runs, 3 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

The first thing we see is:

```
NoMethodError: undefined method `assume' for #<#<Class:0x007facec071a20>:0x007facecbea5a0>
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:35:in `block (2 levels) in <top (required)>'
```

We have not define `assume` in our `TestExtensions` module, hence the error message. Let's do that! (`TestExtensions` should be at the bottom of `lib/juanito_mock.rb`):

```ruby
module JuanitoMock
  ...

  module TestExtensions
    def allow(obj)
      ...
    end

    def assume(obj)
    end

    def receive(message)
      ...
    end
  end

  def self.reset
    ...
  end
end
```

Instead of an instance of `StubTarget`, let's return an instance of `ExpectationTarget`:

```ruby
module JuanitoMock
  ...

  module TestExtensions
    ...

    def assume(obj)
      ExpectationTarget.new(obj)
    end

    ...
  end

  def self.reset
    ...
  end
end
```

Now if you run the tests, it will complain that `ExpectationTarget` is undefined:

```
$ rake
Run options: --seed 58985

# Running:

...E

Finished in 0.001235s, 3237.5687 runs/s, 2428.1766 assertions/s.

  1) Error:
JuanitoMock#test_0004_expects that a message will be received:
NameError: uninitialized constant JuanitoMock::TestExtensions::ExpectationTarget
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:79:in `assume'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:35:in `block (2 levels) in <top (required)>'

4 runs, 3 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

We use `ExpectationTarget` in `assume` because it's a target of a mock expectation (vs. a stub). However, `ExpectationTarget` is actully very similar to a `StubTarget` (a specialized form of `StubTarget`), in that both stubs the original method implementation of an object, but `ExpectationTarget` does a little something extra by checking that the message has been called.

```ruby
allow(object).to receive(:message)
assume(object).to receive(:message)
```

Hence we can make `ExpectationTarget` a subclass of `StubTarget`, and let `to` method in `ExpectationTarget` inherit the implementation of `to` method in `StubTarget` by using `super`. Then we also store the `definition` object to a not-yet-exist `JuanitoMock.expectations` array, so that we can use that to perform our expectation checks later:

```ruby
module JuanitoMock
  class StubTarget
    ...
  end

  class ExpectationTarget < StubTarget
    def to(definition)
      super
      JuanitoMock.expectations << definition
    end
  end
end
```

Now run the tests again:

```
$ rake
Run options: --seed 53163

# Running:

...E

Finished in 0.001286s, 3109.3585 runs/s, 2332.0189 assertions/s.

  1) Error:
JuanitoMock#test_0004_expects that a message will be received:
NoMethodError: undefined method `expectations' for JuanitoMock:Module
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:17:in `to'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:35:in `block (2 levels) in <top (required)>'

4 runs, 3 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

You know the drill. Let's initialize the `expectations` array, lazily:

```ruby
module JuanitoMock
  ...

  module TestExtensions
    ...
  end

  def self.reset
    Stubber.reset
  end

  def self.expectations
    @expectations ||= []
  end
end
```

Run the tests once more and make a little bit more progress:

```
$ rake
Run options: --seed 51829

# Running:

.E..

Finished in 0.001005s, 3980.0243 runs/s, 2985.0182 assertions/s.

  1) Error:
JuanitoMock#test_0004_expects that a message will be received:
NameError: uninitialized constant JuanitoMock::ExpectationNotSatisfied
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:39:in `block (2 levels) in <top (required)>'

4 runs, 3 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

Where's the class `JuanitoMock::ExpectationNotSatisfied`? Oops we don't have that yet, so let's fix it:

```ruby
module JuanitoMock
  ExpectationNotSatisfied = Class.new(StandardError)

  class StubTarget
    ...
  end

  ...
end
```

Define a simple exception class and run the tests again. You'll see that `JuanitoMock::ExpectationNotSatisfied expected but nothing was raised.`:

```
$ rake
Run options: --seed 27046

# Running:

...F

Finished in 0.001435s, 2788.1462 runs/s, 2788.1462 assertions/s.

  1) Failure:
JuanitoMock#test_0004_expects that a message will be received [/Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:39]:
JuanitoMock::ExpectationNotSatisfied expected but nothing was raised.

4 runs, 4 assertions, 1 failures, 0 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

That's expected. We merely created the `ExpectationTarget` and `ExpectationNotSatisfied` classes, and we have not added anything new to the `Stubber.reset` method, so it's right that the new test is failing.

What should `Stubber.reset` do that would make our test pass? Hmm.. `Stubber.reset` should be checking that all of our expectations are verified, and would raise an error if any of the expectations failed. Why don't we add a `verify` method to each `Stubber` instance that would do the checking?

```ruby
module JuanitoMock
  ...

  module TestExtensions
    ...
  end

  def self.reset
    expectations.each(&:verify)
    Stubber.reset
  end

  def self.expectations
    @expectations ||= []
  end
end
```

This works, but if an exceptation is raised when `verify` fails, then `Stubber.reset` would not actually be executed because the exception would have broke the control flow.

We want to make sure that `Stubber.reset` is called even if any expectation raised an exception, and we also want to clear `@expectations` too so that weird things won't happen. Ruby's `ensure` is here to help:

```ruby
module JuanitoMock
  ...

  module TestExtensions
    ...
  end

  def self.reset
    expectations.each(&:verify)
  ensure
    expectations.clear
    Stubber.reset
  end

  ...
end
```

Run the tests again:

```
$ rake
Run options: --seed 12211

# Running:

...F

Finished in 0.001460s, 2738.9588 runs/s, 2738.9588 assertions/s.

  1) Failure:
JuanitoMock#test_0004_expects that a message will be received [/Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:39]:
[JuanitoMock::ExpectationNotSatisfied] exception expected, not
Class: <NoMethodError>
Message: <"undefined method `verify' for #<JuanitoMock::ExpectationDefinition:0x007f89bb4b9640>">
---Backtrace---
/Users/Juan/null/juanito_mock/lib/juanito_mock.rb:97:in `each'
/Users/Juan/null/juanito_mock/lib/juanito_mock.rb:97:in `reset'
/Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:40:in `block (3 levels) in <top (required)>'
---------------

4 runs, 4 assertions, 1 failures, 0 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

Getting there! We have an undefined method `verify` on `ExpectationDefinition`. Let's do the simplest thing to make the test pass! We'll define the `verify` method and just raise `ExpectationNotSatisfied`:

```ruby
module JuanitoMock
  ...

  class ExpectationDefinition
    ...

    def and_return(return_value)
      @return_value = return_value
      self
    end

    def verify
      raise ExpectationNotSatisfied
    end
  end

  ...
end
```

Run the tests! All green!

```
$ rake
Run options: --seed 22996

# Running:

....

Finished in 0.001272s, 3143.7915 runs/s, 3143.7915 assertions/s.

4 runs, 4 assertions, 0 failures, 0 errors, 0 skips
```

But this is clearly not right even though we have all passing tests. We have a gap in our testing and we'll expose that gap by writing a new test:

```ruby
  it "does not raise an error if expectations are satisfied" do
    warehouse = Object.new

    assume(warehouse).to receive(:empty)

    warehouse.empty

    JuanitoMock.reset # assert nothing raised!
  end
```

Now run the tests again:

```
$ rake
Run options: --seed 46019

# Running:

E....

Finished in 0.001292s, 3870.3166 runs/s, 3096.2532 assertions/s.

  1) Error:
JuanitoMock#test_0005_does not raise an error if expectations are satisfied:
JuanitoMock::ExpectationNotSatisfied: JuanitoMock::ExpectationNotSatisfied
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:82:in `verify'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:101:in `each'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:101:in `reset'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:51:in `block (2 levels) in <top (required)>'

5 runs, 4 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

The new test is failing now because `verify` always raises an exception! That's our cue to implement the actual logic for the `verify` method which checks if a method has been invoked.

Again, a simple way to solve this would be to use an invocation count as verification, like so:

```ruby
module JuanitoMock
  ...

  class ExpectationDefinition
    def initialize(message)
      @message = message
      @invocation_count = 0
    end

    ...

    def verify
      if @invocation_count != 1
        raise ExpectationNotSatisfied
      end
    end
  end

  ...
end
```

But we don't really have a way to increment invocation count. Maybe...

Let's look at the following in `Stubber#stub`:

```ruby
@obj.define_singleton_method definition.message do
  definition.return_value
end
```

When we define the singleton method, we are just simply returning the value via `definition.return_value`. Instead, let's modify it to look like:

```ruby
@obj.define_singleton_method definition.message do
  definition.call
end
```

Invoking a `call` method is a standard practice if you want an object to act like a callable piece of code, like a `proc` or `lambda` (which also has the `call` method).

Let's run the tests:

```
$ rake
Run options: --seed 56524

# Running:

.E..E

Finished in 0.001311s, 3815.1804 runs/s, 2289.1082 assertions/s.

  1) Error:
JuanitoMock#test_0001_allows an object to receive a message and returns a value:
NoMethodError: undefined method `call' for #<JuanitoMock::ExpectationDefinition:0x007fa065d1a030>
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:52:in `block in stub'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'


  2) Error:
JuanitoMock#test_0005_does not raise an error if expectations are satisfied:
NoMethodError: undefined method `call' for #<JuanitoMock::ExpectationDefinition:0x007fa065d18b40>
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:52:in `block in stub'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:49:in `block (2 levels) in <top (required)>'

5 runs, 3 assertions, 0 failures, 2 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

Let's add the method `call` for `ExpectationDefinition`:

```ruby
module JuanitoMock
  ...

  class ExpectationDefinition
    ...

    def call
      @invocation_count += 1
      @return_value
    end

    def verify
      ...
    end
  end

  ...
end
```

The `call` method will still return the `return_value` (as was happening earlier with `definition.return_value`), but at the same time, it also increases the `@invocation_count`.

Now run the tests again, and we would be all green again!

```
$ rake
Run options: --seed 47647

# Running:

.....

Finished in 0.001300s, 3846.9144 runs/s, 3077.5315 assertions/s.

5 runs, 4 assertions, 0 failures, 0 errors, 0 skips
```

Great! We now have basic stub and mock functionality for `JuanitoMock`. But we don't have yet the ability to pass (and expect) arguments to stubs.

Let's write a test for that:

```ruby
  it "allows object to receive messages with arguments" do
    warehouse = Object.new

    allow(warehouse).to receive(:include?).with(1234).and_return(true)
    allow(warehouse).to receive(:include?).with(9876).and_return(false)

    warehouse.include?(1234).must_equal true
    warehouse.include?(9876).must_equal false
  end
```

Now run the tests to see what should we do next:

```
$ rake
Run options: --seed 17857

# Running:

E.....

Finished in 0.001458s, 4116.0535 runs/s, 2744.0357 assertions/s.

  1) Error:
JuanitoMock#test_0006_allows object to receive messages with arguments:
NoMethodError: undefined method `with' for #<JuanitoMock::ExpectationDefinition:0x007fb1f2d010f0>
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:57:in `block (2 levels) in <top (required)>'

6 runs, 4 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

We don't have the `with` on `ExpectationDefinition`. Let's do it:

```ruby
module JuanitoMock
  ...

  class ExpectationDefinition
    def and_return
      ...
    end

    def with(*arguments)
      @arguments = arguments
      self
    end

    def call
      ...
    end

    ...
  end

  ...
end
```

The `with` method will accept an array of arguments, made possible using the splat operator (`*`), and we also return `self` to make it chainable.

Run the tests again:

```
$ rake
Run options: --seed 16039

# Running:

...E..

Finished in 0.001207s, 4969.8536 runs/s, 3313.2358 assertions/s.

  1) Error:
JuanitoMock#test_0006_allows object to receive messages with arguments:
ArgumentError: wrong number of arguments (1 for 0)
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:51:in `block in stub'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:60:in `block (2 levels) in <top (required)>'

6 runs, 4 assertions, 0 failures, 1 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

Now we see `ArgumentError`: `wrong number of arguments (1 for 0)`.

Let's decrypt this error message.

What it's saying is that you passed in _1 argument_, but the method defined only requires _0 arguments_.

Luckily there is also a line number telling us where things went wrong:

```
lib/juanito_mock.rb:51:in `block in stub'
```

Line 51 or `Stubber#stub` should be:

```ruby
@obj.define_singleton_method definition.message do
  definition.call
end
```

Let's allow the `define_singleton_method` block to accept splat arguments as well:

```ruby
@obj.define_singleton_method definition.message do |*arguments|
  definition.call
end
```

Run the tests again:

```
$ rake
Run options: --seed 3190

# Running:

..F...

Finished in 0.001697s, 3536.4931 runs/s, 2947.0775 assertions/s.

  1) Failure:
JuanitoMock#test_0006_allows object to receive messages with arguments [/Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:60]:
Expected: true
  Actual: false

6 runs, 5 assertions, 1 failures, 0 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

And we now have a failure on our test:

```ruby
  warehouse.include?(1234).must_equal true
  warehouse.include?(9876).must_equal false
end
```

Let's look at the test again:

```ruby
it "allows object to receive messages with arguments" do
  warehouse = Object.new

  allow(warehouse).to receive(:include?).with(1234).and_return(true)
  allow(warehouse).to receive(:include?).with(9876).and_return(false)

  warehouse.include?(1234).must_equal true
  warehouse.include?(9876).must_equal false
end
```

`warehouse.include?(1234)` is returning false (and failing the test). That's because we have yet to do any matching on the stub argument and so the last stub

```
allow(warehouse).to receive(:include?).with(9876).and_return(false)
```

is the one that's being returned, no matter what arguments are used.

Why is the last stub returned? Remember when we defined the singleton method:

```ruby
@obj.define_singleton_method definition.message do |*arguments|
  definition.call
end
```

We only invoked a definition via `definition.call`, but we didn't actually invoke _the right definition_.

Similar to our `reset` method, we should ([`reverse`](http://ruby-doc.org/core-2.2.2/Array.html#method-i-reverse)) search and [`find`](http://ruby-doc.org/core-2.2.2/Enumerable.html#method-i-find) the definition that matches the method name and arguments:

```ruby
@obj.define_singleton_method definition.message do |*arguments|
  @definitions
    .reverse
    .find { |definition| definition.matches(definition.message, *arguments) }
    .call
end
```

Run the tests again:

```
$ rake
Run options: --seed 61311

# Running:

E.EEE.

Finished in 0.001315s, 4563.6538 runs/s, 1521.2179 assertions/s.

  1) Error:
JuanitoMock#test_0001_allows an object to receive a message and returns a value:
NoMethodError: undefined method `reverse' for nil:NilClass
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:54:in `block in stub'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'


  2) Error:
JuanitoMock#test_0005_does not raise an error if expectations are satisfied:
NoMethodError: undefined method `reverse' for nil:NilClass
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:54:in `block in stub'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:49:in `block (2 levels) in <top (required)>'


  3) Error:
JuanitoMock#test_0003_preserves methods that are originally existed:
JuanitoMock::ExpectationNotSatisfied: JuanitoMock::ExpectationNotSatisfied
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:97:in `verify'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:117:in `each'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:117:in `reset'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:27:in `block (2 levels) in <top (required)>'


  4) Error:
JuanitoMock#test_0006_allows object to receive messages with arguments:
NoMethodError: undefined method `reverse' for nil:NilClass
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:54:in `block in stub'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:60:in `block (2 levels) in <top (required)>'

6 runs, 2 assertions, 0 failures, 4 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

Yikes. 4 tests failed! Let's take a look at the last one:

```
JuanitoMock#test_0006_allows object to receive messages with arguments:
NoMethodError: undefined method `reverse' for nil:NilClass
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:54:in `block in stub'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:60:in `block (2 levels) in <top (required)>'
```

Hmm. Let's look at our implementation again:

```ruby
@obj.define_singleton_method definition.message do |*arguments|
  @definitions
    .reverse
    .find { |definition| definition.matches(definition.message, *arguments) }
    .call
end
```

Why is `@definitions` `nil`? That's because `self` has changed, in a singleton method block like this:

```ruby
@obj.define_singleton_method definition.message do |*arguments|
  ...
end
```

And because instance variables (`@definitions`) are looked up on `self` (which is now `@obj` and not the outer instance), `@definitions` is something different (and unintialized) in the block. We call this a closure.

An easy fix would be to create a temporary variable:

```ruby
module JuanitoMock
  ...

  class Stubber
    ...

    def stub(definition)
      ...

      definitions = @definitions
      @obj.define_singleton_method definition.message do |*arguments|
        definitions
          .reverse
          .find { |definition| definition.matches(definition.message, *arguments) }
          .call
      end
    end

    def reset
      ...
    end
  end

  ...
end
```

Run the tests again:

```
$ rake
Run options: --seed 52635

# Running:

..EEEE

Finished in 0.001867s, 3214.3833 runs/s, 1071.4611 assertions/s.

  1) Error:
JuanitoMock#test_0006_allows object to receive messages with arguments:
NoMethodError: undefined method `matches' for #<JuanitoMock::ExpectationDefinition:0x007ff542c9bf00>
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:55:in `block (2 levels) in stub'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:55:in `each'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:55:in `find'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:55:in `block in stub'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:60:in `block (2 levels) in <top (required)>'


  2) Error:
JuanitoMock#test_0005_does not raise an error if expectations are satisfied:
NoMethodError: undefined method `matches' for #<JuanitoMock::ExpectationDefinition:0x007ff542c9b7d0>
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:55:in `block (2 levels) in stub'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:55:in `each'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:55:in `find'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:55:in `block in stub'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:49:in `block (2 levels) in <top (required)>'


  3) Error:
JuanitoMock#test_0003_preserves methods that are originally existed:
JuanitoMock::ExpectationNotSatisfied: JuanitoMock::ExpectationNotSatisfied
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:98:in `verify'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:118:in `each'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:118:in `reset'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:27:in `block (2 levels) in <top (required)>'


  4) Error:
JuanitoMock#test_0001_allows an object to receive a message and returns a value:
NoMethodError: undefined method `matches' for #<JuanitoMock::ExpectationDefinition:0x007ff542c9ad30>
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:55:in `block (2 levels) in stub'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:55:in `each'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:55:in `find'
    /Users/Juan/null/juanito_mock/lib/juanito_mock.rb:55:in `block in stub'
    /Users/Juan/null/juanito_mock/test/juanito_mock_test.rb:9:in `block (2 levels) in <top (required)>'

6 runs, 2 assertions, 0 failures, 4 errors, 0 skips

rake aborted!
Command failed with status (1): [ruby -I"lib:test:lib"  "/Users/Juan/.rubies/ruby-2.2.2/lib/ruby/2.2.0/rake/rake_test_loader.rb" "test/juanito_mock_test.rb" ]

Tasks: TOP => default => test
(See full trace by running task with --trace)
```

We got rid of the `nil` error, and now we have an undefined method `matches` in `ExpectationDefinition`!

This is the final step, I promise:

```ruby
  class ExpectationDefinition
    ...

    def with(*arguments)
      ...
    end

    def matches(message, *arguments)
      message == @message &&
        (@arguments.nil?) || arguments == @arguments
    end

    def call
      ...
    end

    ...
  end
```

Again, we'll run all the tests:

```
$ rake
Run options: --seed 14495

# Running:

......

Finished in 0.001514s, 3963.4020 runs/s, 3963.4020 assertions/s.

6 runs, 6 assertions, 0 failures, 0 errors, 0 skips
```

Now we have ALL OUR TESTS PASSING!

**C O N G R A T U L A T I O N S**

You've got a basic mocking library!

This library is pretty good now, except with some caveats...
- `with(...)` and calling it with different arguments raises `NoMethodError`
- `define_singleton_method` and `singleton_class` are on `Object` and so stubbing on `BasicObject` is not supported
- `private` methods are not preserved
- `reset`   method should be invoked automatically at the end of each test (`teardown`)

Luckily, RSpec already addressed these and more, so you can just use [rspec-mocks](https://github.com/rspec/rspec-mocks).

Further Reading:
- `allow/expect` discussion in RSpec: https://github.com/rspec/rspec-mocks/issues/153
- The work from this tutorial: [juanito_mock](https://github.com/JuanitoFatas/juanito_mock), original code [ancient_mock](https://github.com/alindeman/ancient_mock/)
- [Building a Mocking Library Slides](https://docs.google.com/presentation/d/1laaQYHFyzcTJzlB9qMmEHyoHIB-S93p9B4L8SbbhoTw/edit#slide=id.p)

Thank you for reading!

_Happy Mocking!_

Till next time :kissing_heart:
_Juanito Fatas_,
_Edits by Winston Teo Yong Wei_

If you tweet or share this tutorial, don't forget to mention and thank @alindeman!

All credits go to him! I only did the writing here. :wink:

Originally posted on jollygoodcode/jollygoodcode.github.io#2.
