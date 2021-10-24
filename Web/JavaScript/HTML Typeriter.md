---
title: Building an HTML Type-Writer
description: "A detailed description of the development process of an HTML TypeWriter element in plain JavaScript using the custom-element API, meta-programming and some recursion magic."
published: true
tags: type-writer, html, javascript, webdev, async, metaprogramming
date: 20210911
---

## Backstory
A few weeks ago, I built a simple type-writer web component: a user would load a JavaScript module and define a `<type-writer>` element with several lines of text. The component would then type out the first line of text, delete it again and rotate it to the back of the list.

```html
<type-writer>
	Here's a first line
	And here's another
	Only plain text supported
</type-writer>
```

This worked well for simple cases, but it was obviously very limited. What if you wanted one word to be emphazised? Or have a line-break? The obvious solution was to extend this component to reproduce an entire DOM-Subtree.

Fast-forward to today, and I find this very nice [article](https://dev.to/auroratide/a-typewriter-but-using-a-new-html-tag-60i) on Dev.to showing off a custom component that does just this. This made it clear: I couldn't just leave my component as it was; it had to be brought to the same level. And so I started coding...

My aim for this article is to use this example to explain some of the nicer things one can do with web components without using any frameworks or libraries. Just one file of JS that runs out of the box in any modern browser.

I'll be trying to reproduce my thought process to some extent, but won't be following the same timeline of when I built this, since features got added piece by piece as it tends to be with programming, and I'd much rather group them by the concepts they rely on.

## Async
One of the first things I figured out while building this component was that object methods can be `async`. Of course they can, they're just functions, after all. But for whatever reason, I didn't expect to be able to just put `async` in front of a normal method definition, but apparently that works perfectly well.

So why is this important? Well to slowly type out some text, one needs some sort of loop that can suspend its execution. Yes, one could also work with callbacks or promises, but it's 2021 and I just don't see a reason not to write blocking-style code instead using `async` and `await`.

So that's the starting point: an `async run()`  method that contains the main animation loop.

Since the only thing worth `await`ing in this case is a timeout, I needed a wrapper around `window.setTimeout`, which I put at the top of my file:

```js
const sleep = time => new Promise(done => setTimeout(done, time*1e3))
```

No magic here: simply create a new promise and resolve it after `time` seconds. Yes, seconds, the SI unit for time. We're writing code in the 21st century and floating point numbers have been around for long enough that there's no benefit in using milliseconds whatsoever other than being used to it. Even POSIX uses seconds for sleep timeouts, so that's what I'm doing.

With that out of the way, here's what a very basic `run()` method would look like, before adding further features:

```js
async run() {
	while (true) {
		// Next item to type out
		let subject = this.children[0]
		// Make a copy in case the original changes while we're typing it
		let content = subject.cloneNode(true)
		// Rotate the subject to the back
		subject.remove()
		this.append(subject)

		await this.typeElement(this.shadowRoot, content)
		await this.emptyElement(this.shadowRoot)
	}
}
```

The important part here are the two functions at the end: These will take care of typing out our cloned element recursively, then deleting it again. The target will be a shadow DOM attached to the custom property in its `connectedCallback`.

## Optional Looping
So now we have an infinite loop, which might not be what the user wants. We need an option to turn the looping on or off. This is actually quite easy though! After all, the loop is just an asynchronous function.

```js
if (!this.loop) return
```
So we can simply return from it at the end of the iteration. What's more, this means that we can disable looping at any moment, and the type-writer will finish the current iteration and then stop.
To resume typing, we'd simply have to call the `run()` method again.

But this leads us to another problem: what if we call `run()` while the loop is already running? To avoid this, I simply added a state variable to the class, and for user convenience, exposed it as read-only:

```js
#running
get running() { return this.#running }

// ...

async run() {
	while (true) {
		if (this.running) return
		this.#running = true
		// The rest of the code
		if (!this.loop) {
			this.#running=false
			return
		}
	}
}
```
Now users can query the read-only property `TypeWriter.running` and they call `run()` a second time, it will simply return immediately.
## Typing
The central part of the element is, of course, the part where it types out the contents. The biggest difficulty here is, that we don't deal with text, but a (potentially very deep) DOM subtree, and we need to type out characters one by one while reproducing the surrounding HTML structure; but we can't type out the HTML text because that's not visible to the user.

A simple solution to this problem is a set of functions, one that loops over the HTML elements recursively and one that handles the actual text content of these elements.

Starting with a function that handles HTML elements, the basic structure would look something like this:

```js
async typeElement(target, elem) {
	for (let child of elem.childNodes) {
		if ("data" in child) {
			await this.typeText(target, child.textContent.replace(/\s+/g, ' '))
		} else {
			let copy = child.cloneNode(false)
			target.append(copy)
			await this.typeElement(copy, child)
		}
	}
}
```
The only two things worth pointing out here are that, before passing the content of a text node to `typeText`, all clusters of whitespace are replaced with a single space to mimic how HTML is rendered anyway. This would mean `<pre>` nodes don't work, so that's something to put on a list of future improvements. The other noteworthy thing is that `"data" in child` is probably not the best way to check for text nodes, but it does work.

For non-text nodes, the function inserts a shallow copy of the given node, appends it to the target and recursively calls itself.

Of course, all function calls need an `await` keyword, as both `typeText` and `typeElement` are asynchronous.

The `typeText` function is even simpler:

```js
async typeText(target, text) {
	let node = document.createTextNode('')
	target.append(node)
	for (let char of text.split('')) {
		node.appendData(char)
		await sleep(this.type)
	}
}
```

all it needs to do is iterate over the string character-by-character and append them to the target node, sleeping for a certain time in between each character.

## Deleting
Deleting of elements looks very similar to typing, except it has to be mirrored. For example, the `emptyText` method will have to remove characters from the back:

```js
async emptyText(target) {
	while (target.data.length) {
		target.data = target.data.slice(0, -1)
		await sleep(this.back)
	}
}
```

and the `emptyElement` function will have to iterate over child elements backwards, deleting them after they have been emptied:

```js
async emptyElement(target) {
	let children = target.childNodes
	while (children.length) {
		let child = children[children.length-1]
		if ("data" in child) {
			await this.emptyText(child)
		} else {
			await this.emptyElement(child)
		}
		child.remove()
	}
}
```

Other than this reversal, both methods look very similar to their typing counterparts; they recursively traverse the DOM subtree and act on each node.
## Events
With the visible parts of the element being implemented now, what's left is to add a usable JavaScript interface. JavaScript has several mechanisms of handling events, but the ones most widely used nowadays are events and promises, each with their own strengths and weaknesses.

Ideally, the API for the TypeWriter might look something like this:

- The Element has a series of Events describing state changes like "finished typing" or "started erasing"
- Each of these events dispatches an actual DOM Event that can be interacted with as usual.
- For convenience, for each of these events, the user can get a Promise that resolves the next time the event is emitted.
- For simpler cases, a user can embed event handling code in the HTML as with other events like `click` (via the `onclick` attribute) and many others.

Since all of these features will be using variants of the same event names, that's the best place to start:

```js
static eventNames = ["Typing", "Typed", "Erasing", "Erased", "Connected", "Resumed"]
```

Static Initialisation Blocks could be used to make looping over this static array and extending the class more readable; but since those aren't a thing yet, the code looks a bit more esoteric:

```js
static eventNames = ["Typing", "Typed", "Erasing", "Erased", "Connected", "Resumed"].map(name => {
	// do stuff with "name"
	return name
})
```

It's worth pointing out that this creates a new array containing the same elements as the first one, which is wasteful. Since this happens only once in a class definition, and the array isn't long, it won't effectively have any performance impact.

Inside this loop, two things will happen:

### Event Promises

For each of the known events, the class should have an attribute that returns a promise. Given the event name, this can be implemented quite easily with a bit of metaprogramming magic:

```js
Object.defineProperty(
	TypeWriter.prototype, name.toLowerCase(),
	{get() { return new Promise(resolve =>this.addEventListener(
		name.toLowerCase(),
		(event) => resolve(event.detail), {once: true})
	)}}
)
```

Simply define a new property on the classes prototype with no setter and a getter that returns a new promise. It becomes a bit hard to read because the event-listener is added in the callback to the Promise constructor, but there's not really much magic going on other than the property definition.

### HTML Attributes

This feature has two parts, only the first of which happens inside the event-name loop:

#### Getting a Function

```js
Object.defineProperty(
	TypeWriter.prototype,
	`on${name}`,
	{ get() {
		return Function(this.getAttribute(`on${name}`))
	}}
)
```

Once again, a new property is defined on the class, but this time there's another bit of meta-programming going on: the getter for the property accesses one of the element's attributes and turns the string into a function.

If, for example, a type-writer tag looks like this:

```html
<type-writer onTyped="console.log(event, this)"></type-writer>
```

then accessing the `onTyped` property on the object would return a function that's equivalent to the following:

```js
function() {
	console.log(event, this)
}
```

#### Calling the Handler

The second part is to call this html-defined event handler, which can easily be done by adding an event listener in the object's constructor:

```js
constructor() {
	super()
	TypeWriter.eventNames.forEach(name => {
		this.addEventListener(name.toLowerCase(), event => this[`on${name}`](event))
	})
}
```

It simply loops over all the event names and adds a listener that makes use of the property to get a function and calls it. The `event` parameter passed to the event callback is just there as a hint that this is an event handler: it doesn't actually get uesd and can be turned into `_event` according to taste.

### Emitting Events

Now the last part is to actually emit some events. For this, I used a simple helper method to reduce boilerplate:

```js
emit(description, detail=undefined) {
	this.dispatchEvent(new CustomEvent(description.toLowerCase(), {detail}))
}
```

There's not much to say about this; it's a very straight-forward helper method that can be called, for example, as `this.emit("typing", content)` right before the call to `typeElement` to signal that the type-writer is about to start typing some text.

-----

## Conclusion

So that's about it. There is, of course, a bunch more code dealing with the more boring technicalities, like skipping `<style>` tags when typing (as they are invisible anyway, and would appear as a random pause to the user if they were typed out), getters for delay-properties like `wait`, the time in seconds to wait after typing an element before starting to delete it, etc.

I hope this article was of some use, specially in illustrating how meta-programming can be used to shorten repetitive code like the adding of event-handlers, which would otherwise have been a long list of `get onTyped() {...}` and `addEventListener("typed", ...)` lines in the class definition, as well as how a set of recursive functions can be used to very easily traverse a DOM subtree.

I am aware that this example doesn't really target only one skill-level, as something like recursively traversing a tree is a lot more "basic" than dynamic property definitions and other meta-programming, but I hope that everyone can find at least one or two things they find helpful.

And last but not least, [here's the actual code](https://github.com/DarkWiiPlayer/components/blob/master/TypeWriter.js), but keep in mind that I changed and ommitted a few things to make the code easier to follow in the article.

What are your thoughts? Would you improve anything about this aproach? Have you ever found yourself using similar tools to solve a problem? Let me know in the comments and happy discussing! 💜