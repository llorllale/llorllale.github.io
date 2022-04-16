---
layout: post
title: "Test-Driven Development By Example"
date: 2022-04-16 10:30:00 -0400
author: George Aristy
categories:
- books
- testing
tags:
- programming
- testing
- unit-test
- kent-beck
- tdd
- extreme-programming
- xp
---

![cover](/assets/img/books/test-driven-development/front-cover.jpg){: .left height="300" width="200" }
Written by [Kent Beck](https://www.kentbeck.com/),
[Test-Driven Development By Example](https://www.amazon.ca/Test-Driven-Development-Kent-Beck/dp/0321146530/)
explains how [TDD](https://en.wikipedia.org/wiki/Test-driven_development) works by way of 2 examples: first building piece
by piece a toy `Money` class, then the initial scaffolds of [xUnit](https://en.wikipedia.org/wiki/XUnit). The third and final
part of the book walks the reader through several TDD patterns as well as refactoring patterns.

Kent Beck built [SUnit](http://sunit.sourceforge.net/) for Smalltalk, and ported it over to Java as [JUnit](https://junit.org/junit5/).

Kent developed [Extreme Programming (XP)](https://en.wikipedia.org/wiki/Extreme_programming) of which TDD is a central component.
Being driven by examples and principles derived from experience, _Test-Driven Development By Example_ needs to be understood
within the context of _Extreme Programming_[^1].

Following are a brief summary and some notes taken from interesting sections of the book.

_Check out some other books I've read on the [bookshelf](/bookshelf/)._

# Summary

_Test-Driven Development By Example_ defines the TDD methodology and demonstrates its use by working through two examples:

* A _Money_ class written in Java that requires a unified API to handle simple arithmetic between amounts expressed in different currencies.
* The beginnings  of a test suite framework (_xUnit_) written in Python.

Several [tips](#testing-tips) and [techniques](#techniques) are provided for writing tests. A brief walkthrough
of some simple design patterns is found as well (see chapter 30).

In Chapter 31 _Refactoring_, Kent makes the effort of codifying into words the different kind of things software engineers
do when refactoring code every day:

* Reconcile differences
* Isolate change
* Migrate Data
* Extract Method
* Extract Interface
* Inline Method
* Move Method
* Method Object
* Add Parameter
* Method Parameter to Constructor Parameter

The amount of verbiage the book invests in the refactoring tips above might sound somewhat scary and daunting, but it
really is nothing more than the bread and butter of every software engineer's day-to-day.

# The Method

The Test-Driven Development method.

1. Write one test.
   1. Always work on one test at a time. Append to a TODO list other test scenarios that you may think of while you work
      on the current one.
   2. How or when to write a test? See [tips](#testing-tips) and [patterns](#green-bar-patterns).
2. Make the test pass by either:
   1. Obvious Implementation: if the implementation is obvious and will take you a short time (seconds? minutes?), then
      just type that in.
   2. Faking It: if the implementation is not obvious or will take you a long time, return a constant that makes the test pass
3. Refactor:
   1. Primarily by removing duplication.
   2. However, your own judgement and knowledge can drive refactors as well (Kent at one point refactored _Money_ to make
      it immutable, something that was not strictly required.
   3. (Optional) Added by me: if you relied on hard-coded constants in your implementation to keep the bar GREEN, make sure
      you change the values of any constants in your tests in order to snuff out constants you may have accidentally 
      forgotten about in the implementation.

Repeat these steps until all tests (see step `1.1`) are implemented and are GREEN.

# Testing Tips

These are covered in Chapter 26 _Red Bar Patterns_ and are about when you write tests, where you write tests, and when you
stop writing tests.

## Write Explanatory Tests

Particularly useful when reporting bugs. Conversely...

## Write Regression Tests

First thing to do when a bug is reported: write a regression test that will be GREEN once the bug is fixed.

## Write "Learning Tests"

Learn how 3rd party code works by writing quick demonstrations in the form of tests. I also use this technique when
learning how std lib components work.

# Test Techniques

## Child Test

If the test case is turning out to be too big, write a smaller test case for a portion of the bigger test case. This could
influence the design by breaking the desired implementation into several methods or objects as opposed to one monolithic
function.

## Mock Object

If your object-under-test relies on an expensive or complicated resource then create a fake version of the resource with
fixed responses:

My notes:

* can influence design by abstracting the complicated dependency out into an interface
* should add caveats for when unit tests do not provide value, such as with non-trivial SQL queries
  * see www.mockobjects.com
  * Kent already considers databases (p. 144). Didn't mention in-memory or lite production-like databases like:
    * [H2](https://www.h2database.com/html/main.html) (Java)
    * sqlite
      * [mattn/go-sqlite3](https://github.com/mattn/go-sqlite3) (Go, requires Cgo for installation)
      * [sqlite JDBC driver](https://mvnrepository.com/artifact/org.xerial/sqlite-jdbc) (Java)
    * [go-mysql-server](https://github.com/dolthub/go-mysql-server)
      * Have run into DATA RACE errors, see [dolthub/go-mysql-server#562](https://github.com/dolthub/go-mysql-server/issues/562)

## Self Shunt

Test that an object communicates correctly with another by having the test object communicate with the test case instead
of an instance of that object.

My notes:

* Should we use this in place of Mock Object?
* Seems to only be useful when implementing observer/listener pattern?

## Log String

Test for the correct sequence of "messages" (aka. method invocations) by logging them to a string and compare the expectation.

For some reason this one seems a little too prescriptive for me.

## Crash Test Dummy

Sometimes you have a test case for critical edge conditions that would be hard or unreliably reproduced in practice,
like testing code that handles a full filesystem error. In such an example, instead of making your test fixture fill
up your filesystem (bad idea) to replicate the error condition, have the fake implementation of your filesystem abstraction
throw a suitable error that your application must handle.

# Green Bar Patterns

Different approaches to getting your tests GREEN. This is probably one of the most contentious parts of TDD.

## Fake It ('Til You Make It)

First implementation for a broken test should just return a constant that matches the test's expectations. Seems highly
important for some people to keep the bar green no matter how fake it is. Kent even qualifies such acts as "sins", although
presumably justified.

I highly recommend others do the following if they're faking behaviour in TDD: once you think the test case _and_ implementation
are "done", alter the test's expected values slightly to sniff out forgotten constants in your implementation. This is especially
crucial if the test asserts the object-under-test sends correct messages to other objects.

## Triangulate

> Abstract only when you have two or more examples.

This is one of the trickier aspects of TDD, mostly due to proponents strongly pushing for _faking it_.

If you have a function `Add` that takes two `int` args and must return their sum, what are the proper TDD steps that take
you from A to Z?

Step A:

```go
func TestAdd(t *testing.T) {
    expected := 4
    actual := Add(2, 2)
    assert.Equal(t, expected, actual)
}

func Add(a, b int) int {
    return 4
}
```

What would be the next step? In these scenarios I would personally opt for randomizing the values of `a` and `b` and asserting
`Add` returns their sum, but some people argue that unit tests should be entirely deterministic, presumably to avoid flaky
tests. It's difficult for me to see how randomizing the inputs in `TestAdd` would make the test flaky but anyway.

Kent recommends adding another sample set of inputs to the test and _triangulate_ the real implementation from those.

Step Z:

```go
func TestAdd(t *testing.T) {
    expected := 4
    actual := Add(2, 2)
    assert.Equal(t, expected, actual)
    
    expected = 7
    actual = Add(3, 4)
    assert.Equal(t, expected, actual)
}

func Add(a, b int) int {
    return a + b
}
```

The problem I have with this is how to do we mechanically reach step Z and not fall astray? Couldn't the implementation
have theoretically been entirely faked?

```go
func Add(a, _ int) int {
    values := map[int]int {
        2: 4,
        3: 7,
    }
    
    return values[a]
}
```

Eventually I came to realise that during the _refactor_ phase (recall [the method](#the-method)) our main goal (according
to TDD) is to remove duplication: duplication within the implementation itself, and duplication between the implementation
_and the tests_. In the example above, `2`, `3`, `4`, and `7` are duplicated between the implementation and the test code.
We _could_ write constants for each of those values, but then we would just be duplicating the names of the constants in
several places. It is then that I realised that `return a + b` leads to the least duplication overall in the codebase.
Having gotten there, what's to stop us from deleting one of the tests? And now we're back at step A.

... and _that_ is a level of nuance absent in most conversations about TDD that I've seen.

## Obvious Implementation

The answer to the conundrum above: if the implementation is sufficiently obvious to you (eg. `Add`) then just implement
it. There is no need for fake implementations or runarounds with triangulation.

... or so they say. Things get tricky while pair-programming: is the implementation also obvious to your pairing partner?
How large is the gap between skill and experience levels?

## One to Many

> How do you implement an operation that works with collections of objects? Implement it without collections first, then
> make it work with collections.

A little too prescriptive if you ask me.

# Questions

Questions selected from chapter 32 _Mastering TDD_.

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

## What don't you have to test?

The gist is:

> Write tests until fear is transformed into boredom.

Simple list:

* Conditionals
* Loops
* Operations
* Polymorphism

## How do you know if you have good tests?

Attributes of tests that suggest a design is in trouble:

* Long setup code
* Setup duplication
* Long running tests
* Fragile tests
  * Note: different from flaky tests. These are tests with hidden or unexpected coupling to other parts of the system.

## How does TDD lead to frameworks?

TDD focuses on the realities of _today_, discarding everything else (YAGNI).

> Code for tomorrow, design for today.

Presumably what happens with TDD in practice is that removal of duplication along with respect for SOLID principles
("Open/Closed" was the only one mentioned here) leads to a natural evolution of the system's design where changes are
effected only in specific spots as needed. There is an amusing statement here:

> At the limit, where you introduce the variations very quickly, TDD is indistinguishable from designing ahead.

This is just YAGNI stated in a different way.

## How much feedback do you need?

In other words, _how many test cases should I test for?_

The answer is, it depends. Here are some questions to guide you:

* What are the chances of some weird edge cases occurring?
* What would be the impact of these edge cases?
* What is our target [Mean Time Between Failure](https://en.wikipedia.org/wiki/Mean_time_between_failures) rate?

Here is a tantalizing paragraph (emphasis mine):

> TDD's view of testing is pragmatic. In TDD, the tests are a means to an end - the end being code in which we have
> great confidence. **If our knowledge of the implementation gives us confidence even without a test, then we will not
> write that test.** Black box testing, where we deliberately choose to ignore the implementation, has some advantages.
> By ignoring the code, it demonstrates a different value system - the tests are valuable alone.

In this quote, if we take in everything up to and including the part in bold, one might conclude that Kent/TDD is OK with
programmers choosing not to test certain arbitrary parts of the code. This turns on its head everything we know about
testing so far, including the confidence that good tests and test coverage bring when refactoring, making sure everything
works, etc. However, the last bit on black box testing makes me think this paragraph is really just talking about the choice
of not testing internal implementation details, which I completely understand and generally agree with.

## Can you drive development with application-level tests?

Interesting conundrum.

The risk with driving development with unit tests is these are only indirectly connected to the actual user story, so we
run the risk of implementing a piece that may not actually be needed.

The obstacle with driving development with application-level tests[^2] is setting up the fixtures, being
slower and more difficult to troubleshoot, as well as organizational issues surrounding resource allocation at specific
times during the development lifecycle (devs+users) writing tests far in advance of actual development. The dreaded RED
bar will stay red for quite a while.

# Footnotes

[^1]: See [Extreme Programming Explained: Embrace Change](https://www.amazon.ca/Extreme-Programming-Explained-Embrace-Change/dp/0321278658), also by Kent Beck.
[^2]: Interesting that _Application Test-Driven Development (ATDD)_ does not seem to come up in search results. I think it's another term for [Acceptance Test Driven Development](https://www.agilealliance.org/glossary/atdd). The link says Kent mentioned ATDD in this book.
