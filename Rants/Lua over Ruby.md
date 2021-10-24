---
title: Why I prefer Lua to Ruby
published: true
tags: Lua, Ruby
date: 20190401
---

So Lua and Ruby are two rather similar languages in many aspects. There's a lot of articles explaining what makes them so similar and many of the more superficial differences.

Today I'd like to point out some reasons that have shaped my opinion on the two languages.

I will risk sounding like a hater, but I'd like to point out that I don't particularly dislike Ruby. There's many positive things about it, but since I do prefer Lua, I just chose to point out some of its problems today.

# Speed

It'd be easy to just say "Lua fast, Lua good" and be done with it. In reality though, things aren't always that easy.

### File Size

The thing about Lua is, it's very small. Not only does this mean that it fits almost everywhere, but also that it loads very fast

```bash
> time ruby -e 'puts "hello"'
hello

real	0m0.059s
user	0m0.054s
sys 	0m0.005s

> time lua -e 'print "hello"'
hello

real	0m0.003s
user	0m0.003s
sys 	0m0.001s
```

This only makes a difference when you're calling the executable many times in a row, but the difference does add up over time.

----------------------

### Functions vs. Methods

The next thing to consider is that, in Lua, functions are stored in variables, and are therefore easy to look up.

Ruby, on the other hand, has to look up methods for everything. For short methods (let's say, adding two numbers) this can mean a significant overhead.

```bash
> ruby -e 'puts self.class.ancestors'
Object
Kernel
BasicObject
```

Even the main object every ruby script runs in inherits from 3 ancestors.

It should be noted that Lua isn't immune to this problem. When writing object-oriented code, this also ends up happening. The difference is that in Lua the programmer must do this explicitly, while in Ruby it happens all the time.

----------------------

### Strings / Symbols

~~This may surprise some people, but Lua actually has a huge disadvantage to Ruby in terms of speed: It has no Strings in the way Ruby has them. All strings in Lua are automatically interned. Ruby has interned strings as well; it calls them *Symbols*.~~

~~This has its upsides and, overall, was probably a smart decision, but it also means reading in a long text file takes much longer in Lua. Imagine calling `to_sym` on every line in Ruby.~~

`<edit>`

Since writing this post, I have double-checked this and discovered that I apparently misunderstood this or just remembered it incorrectly: Lua *does* intern all **short** strings by default, however, above a certain length, this doesn't happen anymore. Strings that are too long for interning don't get hashed immediately, but they do get hashed once it becomes necessary (for example when comparing them to another string or indexing a table) and will from then on use just use that hash.

This pretty much means that, in most cases, Lua wins over Ruby even when working with long (but immutable) strings.

However, the downside that Lua strings are immutable remains, and modifying a string means creating a new, modified copy of the string.

`</edit>`

----------------------

### Vararg functions

If I was asked which of the two languages had the powerful implementation of variadic functions, I'd 100% say Ruby. You can mix and match many kinds of syntactic constructs that capture additional arguments into both arrays and hashes.

But, with great strength comes... not so great performance.
Let's consider the following piece of code:

```ruby
def foo(bar, *rest)
    do_something(bar)
    do_something(*rest)
end
```

Every time the foo method is called, ruby needs to instantiate a new array `rest` and collect the excess arguments into it. This ends up happening a lot and makes variadic methods very unsuited for code that needs to perform well.

Consider the equivalent code in Lua:

```lua
function foo(bar, ...)
    do_something(bar)
    do_something(...)
end
```

Here, there's no array involved. The function can just leave bar on the stack, call `do_something` telling it it has 1 argument, then pop bar from the stack and call `do_something` again, telling it how many items are left on the stack.

This means writing functions like this is way more viable even when your code needs to run as fast as possible.

----------------------

### Mentality

One difference that probably makes a way larger difference than most people would assume is the difference in mentality between the two communities.

When asked why Ruby is so great, the general response from its community will be something along the lines of "Because it's fun to write!". Many Ruby examples out there seem to throw performance out the window before even starting. This isn't necessarily a bad thing, but it ultimately leads to people writing libraries that run way slower than they could.

My experience with the Lua community has been vastly different. A simple google search brings up way more relevant and detailed information on how to improve performance in Lua than in Ruby, even though the latter has a much larger community that also seems to write way more about it.

----------------------

### LuaJIT

Lua is already very fast on its own. LuaJIT though, that's a completely different level. There have been examples where JITed Lua code can even run faster than equivalent C code, because the compiler sometimes has more awareness of the code it's optimizing (After all, it keeps track of the code as it's being executed)

Ruby has made a huge step in the right direction with its own JIT Compiler, but that's still nowhere near the performance improvements of LuaJIT when compared to PUC Lua, the "reference" Lua implementation.

-------------------------------------

# Simplicity

Leaving performance aside now, there's another reason why I consider simplicity a very positive feature of Lua: It's not only easy to learn, but also easy to master.

### Modularity

This is probably one of the things I hate the most about Ruby. No matter how hard you try, you will never get rid of global state. At the very least you will have some modules and classes polluting the global environment, and there is no way to load a library into a contained space.

This means, for example, that it's not possible to load two different versions of one library without having to go through its source code and renaming things everywhere.

```ruby
require 'some_class'

foo = SomeClass.new # Where did this come from?!
```

In Lua, on the other hand, you can just rename the file and load it into another local. How things are called internally doesn't matter to the host program.

```lua
local someclass = require 'someclass'

local foo = someclass.new()
```

----------------------

### Side effects

Ruby tries to be as comfortable as possible for the developer. I often find myself wishing it didn't

Consider the following example:

```ruby
require 'missile_cruiser'

MissileCruiser.new.last_fired
```

What happens there? One would assume, the variable `last_fired` will return the last missile that was fired. Since we didn't fire one, it would be reasonable for this to be `nil`.

But wait, what if it's a method?

Maybe it will raise an error because we didn't fire any missile yet?

Even worse, maybe some developer thought if we wanted to know about the last missile, we probably wanted to fire one, so the method just fires a missile and returns that one?

This kind of thing happens often in Ruby. The lines between what is a value and what is code that gets executed are blurred.

----------------------

### (in)Consistencies

Try the following code in `irb`:

```ruby
puts 1/0
puts 0/0
puts 1.0/0
puts 0.0/0
```

Things like that make a language (and, by extension, programs written in it) harder to understand at first glance, specially to newcomers. No language will ever be 100% consistent, but these inconsistencies should still be reduced whenever possible.