---
title: Tabs are objectively better than spaces, and here's why
published: true
description: Here's why I think tabs are objectively better than spaces
tags: indentation, tabs, spaces
date: 20210215
---

# The Debate

This is probably one of the longest ongoing bikeshedding debates in the programming community: Should we indent our code with **Tabs** or with **Spaces**?

In this post, I will do my best to explain why **tabs** are the right choice, not only in my personal opinion, but objectively.

# Indentation

First of all, I want to define the scope of my argumentation: I am referring to **indentation**, not **alignment**.

The former depends on semantics, the latter on word lengths. For obvious reasons, using tabs for alignment is not possible; whether alignment should be a thing at all (hint: it shouldn't) or how it should be achieved is a different debate and irrelevant for this post.

# Semantics

The most puritan argument for tabs is probably the semantic information they add to the code. I have never seen a real-world example where this matters, but as programmers we often like to obsess over using the right "thing", be it a HTML element or an ASCII character.

# Consistency

The main argument I've heard defending spaces is that code looks "consistent" everywhere. Whether you post your code on Stack-Overflow, GitHub Gists, or on your blog; it will always be indented by the same width.

Code is not visual art. The indentation width doesn't alter the codes meaning in any way and, unlike with alignment, changing it doesn't break the visual layout of the code.

**There is no reason whatsoever why someone else reading my code should experience it with the same indentation width that I wrote it in.**

# Customizability

I personally prefer a tab-width of three spaces. Two is just barely too short to follow through deeper nested blocks of code. Four is one more space-width than I need.

So the question is: Why would *you* have to read my code with such an awkward tab width, just because to my uncommon taste <!-- unintentional skyrim reference --> that seems like the right value?

The answer is, of course, you shouldn't. You should be able to read *my* code the way *you* prefer to read it.

**Everyone should be able to read code with their own preferred settings.**

# Accessibility

So far I've looked at customizability as a convenience feature. I *like* 3-space indentation more, so I *want* to read code that way.

But for some people it goes beyond just preference.

I've seen posts and comments of quite a few developers with poor eyesight. For some, 2 spaces is just not enough indentation, making it unnecessarily hard to read code, others might need to use very large font sizes, and prefer shorter indentations to save screen space.

# Consistency (again, but differently)

This is by far the most ridiculous reason, or group of reasons people make to argue for spaces:

Projects indented with tabs—so the claim—cause additional work when people contribute code that is indented with spaces, requiring additional moderator intervention.

Needless to say, this argument works exactly the same both ways, and if anything, says more about the typical space-user than the typical tab-user.

Regardless of preference, in the age of linting tools and CI pipelines, this is just not an issue any more. We can automate the process of checking indentation, or even have it fixed automatically.

# Conclusion

There is not a single good reason to prefer spaces over tabs. The whole space-indentation mythology is nothing but ridiculous non sequiturs and false claims.