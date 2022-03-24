---
title: An Introduction to Coroutines
description: "A language-agnostic introduction to the concept of Coroutines"
published: true
tags: beginner coroutines parallelism
date: 20211120
---

## Preamble
The aim of this article is to be a mostly language-agnostic introduction to coroutines. All code used will be a pseudocode, which will somewhat resemble JavaScript.

* Subroutines are defined as `arguments ⇒ body`
* Subroutines without arguments will be shortened to `⇒ body`
* Multi-statement subroutines use braces `{}`

## What are Coroutines?
In describing coroutines, the introductory sentence of the [wikipedia article](https://en.wikipedia.org/wiki/Coroutine) already gets very close to the way I would describe it:

> **Coroutines** are [computer program](https://en.wikipedia.org/wiki/Computer_program "Computer program") components that generalize [subroutines](https://en.wikipedia.org/wiki/Subroutine "Subroutine") for [non-preemptive multitasking](https://en.wikipedia.org/wiki/Non-preemptive_multitasking "Non-preemptive multitasking"), by allowing execution to be suspended and resumed.

Put even more simply: A coroutine is *like a function* that can pause itself.
If we think of a normal function, the way it works is that we **call** the function, the function **executes** and at some point, it **returns** back to where it was called.

In a similar way, a very simple coroutine will do the same thing: We will **create** the coroutine, it will **execute** and at some point it will end and (implicitly) **yield** back to the calling code.

The big difference is: A coroutine can **yield** more than once, and will be paused in between. And that is really all there is to them, from a technical level. A simple example of this would look like this.

## Classifying Coroutines
The 2004 paper [Revisiting Coroutines](http://www.inf.puc-rio.br/~roberto/docs/MCC15-04.pdf) classifies coroutines in two important ways: *Symmetric vs. Asymmetric* and *Stackful vs. Stackless*. The paper also distinguishes on whether coroutines are handled as values by the language, but that distinction is less important to understanding how they fundamentally work.

### Control Transfer Mechanism
The way coroutines transfer control can happen in two ways.

Asymmetric coroutines are more similar to how functions work. When a coroutine *A* resumes a coroutine *B*, *B* will at some point yield back to *A*, just like how any function will eventually return to its caller. We can think of these coroutines as organised in a stack, just like how functions are, but this is not the same as being *stackful*.

An important implication of this type of control transfer is that once a coroutine hands over control to another by resuming it, it can only ever be handed back control from this coroutine. In other words, it cannot be *resumed* from the outside, only *yielded* to.

To illustrate this: "When you lend a pencil to Bob, you know you will eventually get the pencil back from Bob and nobody else."

This will be represented in pseudocode by the functions `resume` ("hand control down") and `yield` ("return control back up")

---

Symmetric coroutines work a bit differently. Coroutines can freely transfer control to any other coroutine, instead of just "up and down".

Unlike asymmetric coroutines, this one-way control transfer means a coroutine can hand over control to another and be handed back control by a completely different one.

Continuing the pencil analogy: "When you lend a pencil to Bob, you may later get it back from Steve, Larry, or never get it back at all."

In pseudocode, this will be represented by the `transfer` function.

---

The main advantage of asymmetric coroutines is that they offer more structure. Symmetric coroutines let the user freely jump back and forth between coroutines, in a similar way to `goto` statements, which can make core hard to follow.

### Stackfulness
Another important way to categorize coroutines is whether every coroutine has its own stack. This distinction is much harder to explain in theory, but will become clear in examples later on.

Stackless coroutines, as the name implies, don't have their own call stack. What this means in practice is that the program has no way of tracking their call stack once they yield control, so this is only possible from the function on the bottom of the stack.

Stackful coroutines, on the other hand, have a separate stack for every coroutine, so they can be paused from anywhere inside the coroutine.

A complete explanation of why this is and how it works could easily be its own article, so I will be skipping it for now. The important part to remember here is that Stacful is "better" in that it lets you do more, but also harder to implement in a language, specially if it was added later on and not part of the initial language design.

---

Many programming languages actually have *stackless* *asymmetric* coroutines; JavaScript, for example, calls them *generators*.

Some languages even have a mix of both: Ruby *fibers* can both use `resume`/`yield` semantics, but they can also freely transfer control freely with the `transfer` method.

Windows even provides an OS-level API for coroutines: It calls them Fibers, and they are *stackful* and *symmetric*. Linux does not provide any coroutine API yet.

## Why are they useful?
On an abstract level, the strength of coroutines is to manage state. Since they remember where they left off for the next time they're resumed, they can use control-flow to save state that would otherwise have to be stored in variables.

### Animation
As a simple example, imagine an object in a game. The object has an `update` function that will be called repeatedly by the engine, and as an argument, it will receive the time (in seconds) since the last time it was called. This is a very typical setup for simpler games.

Implementing a simple animation, for example, along the edges of a square, would require storing the animation state in some sort of data-structure so the `update` function knows where to continue the animation. Although in this case one *might* be able to get away with just `x` and `y` coordinates (which are likely already present in the object) and some convoluted if/else logic, this code would still look unintuitive.

**Coroutines to the rescue!** Now consider extending the setup like this:

Along with the `x` and `y` attributes, the object also has a `behavior` coroutine. The only thing the `update` method does, is to resume this coroutine every time.

```
object.update = delta_time ⇒ resume(object.behavior, delta_time)
```

`resume`, in this pseudocode language, is the function that resumes a suspended coroutine asymmetrically, meaning it will pause the code here until the resumed coroutine yields.

For this to work, a bit of extra semantics has to be introduced: Just how functions can have *arguments*, it is common that *yielding* and *resuming* coroutines can also pass arguments along. In the above pseudocode, this will be represented as an extra argument to both `resume` and `yield`, that would be *returned* by the matching `yield` and `resume` calls. This is a very common way to handle passing around data between asymmetric coroutines.

Now, with this setup, the `behavior` coroutine could look something like this:

```
object.behavior = coroutine( ⇒ {
	while true {
		while object.x < 10
			object.x += yield() * object.speed
		while object.y < 10
			object.y += yield() * object.speed
		while object.x > 0
			object.x -= yield() * object.speed
		while object.y > 0
			object.y -= yield() * object.speed
	}
)
```

where `coroutine` is a function that takes a subroutine and turns it into a coroutine, without actually starting it and `yield` is a function that suspends the current coroutine and yields back to the "parent" coroutine that resumed it.

It looks a bit like magic. The animation code *looks* like it should simply block the game in an endless loop, but it doesn't, because it runs inside a coroutine that yields after every step. But the state of the animation is still represented as a simple nested loop.

This can be taken a step further though. Consider the following example:

```
object.behavior = coroutine ( ⇒ {
	while true {
		object.move_right(10)
		object.move_down(10)
		object.move_left(10)
		object.move_up(10)
	}
})

object.move_right = distance ⇒ {
	while distance > 0
		delta_x = yield() * object.speed
		object.x += delta_x
		distance -= delta_x
}
```

This could be refactored into a single `move(axis, distance)` function, of course; but the additional code to figure out the direction would clutter the code a bit too much for this example.

The important thing here is, that the top-level function of the coroutine never `yield`s; instead, it calls a `move_*` function that takes care of yielding itself. This is where **stackfulnes** comes into play again: Only **stackful** coroutines can do this. In languages with stackless coroutines, like javascript, code like this would likely be rejected by the compiler.

Put very simply: the reason for this is that when `move_right` yields, it needs to remember where it needs to return to after it resumes. This information is what's on the stack, so a coroutine without its own stack cannot remember from nested functions.

### I/O Event Loops
Another application of coroutines is handling the complexity if asynchronous code. Lua has done this for years now, Ruby recently adopted the same idea, and languages like Elixir have been doing a very similar thing as part of the language for ages.

But how exactly can coroutines help with this? Simple: by yielding to an event-loop, which will resume them once a certain event happens. While in practice this is a bit more complicated, the core idea is this:

* All code runs inside coroutines (In some languages this is always the case, in others the framework would have to wrap the user code manually)
* Functions that need to await asynchronous tasks yield from the current coroutine
* When a coroutine yields, a scheduler will decide what coroutine to resume next, or simply sleep until any new "event" is available.

This should sound very familiar to anybody who has worked with `async`/`await` before. It is a very similar concept. Then only difference is that functions are always synchronous, and all functions are implicitly awaited.

This has one significant advantage: While the program itself either uses non-blocking IO or APIs that resume it whenever any of the awaited inputs is available, the user writes codes that *looks* like blocking code. And it is in fact "blocking", on the level of the coroutine, but will never block other parts  of the same program.

At the same time, this is still cooperative multi-threading, so no section of code will be interrupted from the outside. Only operations that yield can lead to race-conditions, but two consecutive non-yielding operations will never have their state messed with in between.

This makes unsafe code much easier to spot:

```
c = global(counter)
c = c + 1
global(counter) = c
```

The above code is very obviously safe, because the code will never be suspended for other code to run in the meantime.

In a multi-threaded environment, this code could lead to errors: the scheduler could suspend this thread after the first line, and some other thread could increment the counter. Then, when this thread was resumed, the third line would overwrite the `counter` variable with an old value.

---

With coroutines, it is still possible to write buggy code susceptible to race-conditions, but only by explicitly yielding, or calling a function that does so.

```
c = global(counter)
c = c + 1
sleep(3)
global(counter) = c
```

This code is obviously unsafe: in the 3 seconds that this coroutine is sleeping, some other code may also increment the counter, which would then be overwritten by this coroutine after it resumes.

However, we can safely assume that the code will *never* be interrupted between the first and the second line, or even worse, in between two steps of the same line.

---

## Conclusion

There is, of course, lots more to be said about coroutines, and how they a reintegrated in different languages. But this introduction should give a good enough idea of how they fundamentally work.