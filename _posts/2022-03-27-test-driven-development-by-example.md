---
layout: post
title: "Test-Driven Development By Example"
date: 2022-03-27 14:51:00 -0400
author: George Aristy
categories:
- programming
- testing
tags:
- programming
- testing
- unit-test
- kent-beck
- tdd
---

![cover](/assets/img/books/test-driven-development/front-cover.jpg){: .left height="300" width="200" }
Written by [Kent Beck](https://www.kentbeck.com/),
[Test-Driven Development By Example](https://www.amazon.ca/Test-Driven-Development-Kent-Beck/dp/0321146530/)
explains how [TDD](https://en.wikipedia.org/wiki/Test-driven_development) works by way of 2 examples: first building piece
by piece a toy `Money` class, then a toy version of [xUnit](https://en.wikipedia.org/wiki/XUnit). The third and final
part of the book walks the reader through several TDD patterns as well as refactoring patterns.

Kent Beck built [SUnit](http://sunit.sourceforge.net/) for Smalltalk, and ported it over to Java as [JUnit](https://junit.org/junit5/).

Kent developed [Extreme Programming (XP)](https://en.wikipedia.org/wiki/Extreme_programming) of which TDD is a central component.
Being driven by examples and principles derived from experience, _Test-Driven Development By Example_ needs to be understood
within the context of _Extreme Programming_[^1].

_Check out some other books I've read on the [bookshelf](/bookshelf/)._

# Summary

_Test-Driven Development By Example_ defines the TDD methodology and demonstrates its use by working through two examples:

* A _Money_ class written in Java that requires a unified API to handle simple arithmetic between amounts expressed in different currencies.
* The beginnings  of a test suite framework (_xUnit_) written in Python (TODO xUnit for Python)

# The Method

P.11:

1. Write one test.
   1. Always work on one test at a time. Append to a TODO list other test scenarios that you may think of while you work
      on this one.
2. Make the test pass by either:
   1. Obvious Implementation: if the implementation is obvious and will take you a short time (seconds? minutes?), then
      just type that in.
   3. Faking It: if the implementation is not obvious or will take you a long time, return a constant that makes the test pass
3. Refactor to remove duplication.

> TODO removing duplication is not the only driver of design in TDD. You can also apply your own judgement and knowledge
> of best practices eg. immutability (P. 4), encapsulation (Ch. 4 "Privacy").

# Questions

## How large should my steps be?

Chapter 32 _Mastering TDD_ provides some guidance. The book stops short of making strong claims, but the general recommendation
seems to be to go small. Ultimately the size of the steps is up to you and your tolerance level. You get hints of this
flexibility in the choice between _Obvious Implementation_ and _Fake It_ in [The Method](#the-method) above.

> When I use TDD in practice, I commonly shift between these two modes [...]. When everything is going smoothly and I
> know what to type, I put in Obvious Implementation after Obvious Implementation (running the tests each time to ensure
> that what's obvious to me is still obvious to the computer). As soon as I get an unexpected red bar, I back up,
> shift to faking implementations, and refactor to the right code. When my confidence returns, I go back to Obvious
> Implementation.
> 
> Chapter 2: _Degenerate Objects_.

# Footnotes

[^1]: See [Extreme Programming Explained: Embrace Change](https://www.amazon.ca/Extreme-Programming-Explained-Embrace-Change/dp/0321278658), also by Kent Beck.
