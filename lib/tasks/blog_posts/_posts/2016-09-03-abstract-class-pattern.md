---
layout: "post"
title: "Abstract Class Pattern in Ruby"
date: "2016-09-03 19:00:00"
description: "Introduce Abstract Class Pattern in Ruby."
tags: "ruby"
---

In this post, I'll share how to implement the Abstract Class Pattern in Ruby.

## What is Abstract Class Pattern?

[Abstract Class](http://c2.com/cgi/wiki?AbstractClass) on c2.com:

- cannot create instance
- provide interface

Ruby doesn't have the native support of Interface and Abstract Class. But we can still (sort of) implement it.

## The Base Class

Suppose our base class is called `Family`:

```ruby
class Family
  def initialize(_env)
    raise "Subclass must overwrite initialize"
  end
end
```

[Set][set] is an idiomatic way to store unique objects. We override the `initialize` so cannot create an instance of this base class.

## Provide interface

```ruby
class Family
  ...

  def self.hungry?
    raise "You need to include a function for #{self} for hungry?"
  end
end
```

We add a method in the base class (“interface”) that raises when the child class trying to call but not implemented it.

## Track subclass

```ruby
require "set"

class Family
  def self.inherited(child_class)
    child_classes.add child_class
  end

  def self.child_classes
    @child_classes ||= Set.new
  end

  ...
end
```

The [inherited][ruby-inherited] is called when a subclass is created, let us keep track of child classes.

Here we use class instance variable (`@child_classes`) instead of class variable (`@@child_classes`):

> A class variable (`@@`) is shared among the class and all of its descendants. A class instance variable (`@`) is not shared by the class's descendants.
> :bulb: [Difference between class variables and class instance variables?](http://stackoverflow.com/questions/3802540/difference-between-class-variables-and-class-instance-variables)

And there seems no good use of class variables, so please try to avoid it.

With this, we will be able to find out who is `hungry?`:

```ruby
hungry_kids = Family.child_classes.select(&:hungry?)
```

## Any concrete examples?

Yes! I learned from the codebase of [danger/danger][danger]:

- [Base Class](https://github.com/danger/danger/blob/1f2ae76603e9bbfd72ed9c85ce904853135021e9/lib/danger/ci_source/ci_source.rb)
- [Child Classes](https://github.com/danger/danger/tree/1f2ae76603e9bbfd72ed9c85ce904853135021e9/lib/danger/ci_source)
- And [the application of this Abstract Class Pattern](https://github.com/danger/danger/blob/1f2ae76603e9bbfd72ed9c85ce904853135021e9/lib/danger/danger_core/environment_manager.rb)

That's it.

Thanks for reading! :heart:

[danger]: https://github.com/danger/danger
[ruby-inherited]: https://ruby-doc.org/core-2.3.1/Class.html#method-i-inherited
[set]: http://ruby-doc.org/stdlib-2.3.1/libdoc/set/rdoc/Set.html
