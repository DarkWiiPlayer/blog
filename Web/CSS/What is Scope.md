---
title: What is CSS @scope and why should I care?
published: true
description: "A short introduction to the new CSS @scope rule, the history of CSS scoping and what makes it useful for different areas of web-development"
tags: css,scope,components,vanilla
date: 20220316
---

## A brief history of Scoping and CSS

Scoping CSS to certain regions of the DOM is not a new idea.

The `scope` attribute for `<style>` tags was one attempt at addressing it. Nowadays, it is sadly deprecated though.

```css
/* ⚠ This is deprecated. It doesn't and won't work ⚠ */
<div>
   <style scope>p { color: red; }</style>
   <p>Red Text</p>
</div>
<p>Normal Text</p>
```

Many front-end frameworks implement their own scoping by prefixing CSS rules with IDs and classes and adding those to their HTML output. However, this requires a lot of complexity in the framework and is still brittle.

Then components came into the browser, in the form of custom elements and shadow-DOM. In fact, one part of shadow-DOM is that all the CSS inside it is scoped. However, it doesn't permit outside CSS to leak inside either.

## Native Scoping is still on the table

The exact reason why `scope` was originally abandoned seems a bit fuzzy. Some will tell you it was because browsers didn't want to implement it, others say that it was just about letting web components become a thing, then re-evaluate the need for pure CSS scoping.

Whatever the case may be, CSS authors still seem to have an interest in scoping being a thing, for a variety of reasons.

## CSS Scoping Revived: `@scope`

The `@scope` rule is the newest attempt at bringing CSS scoping to the browser. It is described in the [Working Draft](https://www.w3.org/TR/css-cascade-6/#scoped-styles) of the *CSS Cascading and Inheritance Level 6* specification. 

In other words: it's far from being usable. But there's still plenty of reasons to be hyped about it! 😁

-----

The way this would work is simple: we would first define where we want our rules to apply. We can use any CSS selector here, but to avoid distractions, I will be using the `outer-component` and `inner-component` custom elements for the rest of this article.

```css
@scope (outer-component) {
   p { color: red; }
}
```

Any rules written inside this scope block will only apply inside an element described by the selector.

```html
<p>This text is black</p>
<outer-component>
   <p>This text is red</p>
</outer-component>
```

And we can also describe a lower boundary to this scope; another selector telling the browser that the scope should *not* apply to a certain sub-tree.

```css
@scope (outer-component) to (inner-component) {
   p { color: red; }
}
```

```html
<outer-component>
   <p>This text is red</p>
   <inner-component>
      <p>This text is black</p>
   </inner-component>
</outer-component>
```

## Why should we be hyped about it?

The example with two nested custom elements already shows one possible use-case. Having styles apply only inside specific components without prefixing every selector with the component name is already useful.

But the addition of a lower boundary to prevent styles from leeking into nested components makes this incredibly useful, specialy in the modern front-end landscape is constantly moving away from monolithic structures and towards small, portable and interchangeable components.

If you're writing plain CSS for some vanilla JS components, you will be able to write CSS that's much more similar to what frameworks like svelte allow you to do: Write a bunch of rules and they will only apply inside the component. Imagine doing that with direct-child selectors 😵‍💫

here's an example of where this could be useful without any components or custom elements:

```css
th { background: black; color: white; }
@scope (table.vertical) to (table) {
   th::after { content: ':' }
   th { all: initial; }
}
```

-----

Meanwhile, for authors of such component frameworks, native CSS scoping will vastly reduce the complexity they have to deal with as they will no longer have to automatically prefix selectors nor add IDs or classes to the elements they should apply to.

A somewhat simplified version of what such a framework could do:

```js
component_css = `
	@scope ([data-component="${component.name}"]) to ([data-component]) {
		${component.styles}
	}
`
```

-----

Even if you just use these frameworks, which already implement CSS scoping, there might be some benefits for you. Most importantly: since the scoping happens in the browser at runtime, frameworks don't need to know about your elements in order to style them, so there will be much less friction between frameworks and manually generated content. Inserting some HTML via `.appendChild()` would "just work".

```js
// No code example for this one, because these problems only tend
// to surface once the project becomes a little bit more complex
// and several libraries trying to work together.
```
