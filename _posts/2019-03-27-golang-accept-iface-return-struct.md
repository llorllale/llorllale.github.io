---
layout: post
title: Golang - Accept Interfaces, Return Interfaces
excerpt: TLDR - Accept interfaces, return interfaces (unless there aren't any).
date: 2019-03-27
author: George Aristy
tags:
- go
- golang
- learning-go
- go-proverbs
---

*This post is part of a [series](https://llorllale.github.io/tags/#learning-go) where I do my best to organize my thoughts around Go: its paradigms and usability as a programming language. I write this as a Java programmer that respects the principles of [Elegant Objects](https://www.elegantobjects.org/).*

[**Accept interfaces, return structs**](https://github.com/golang/go/wiki/CodeReviewComments#interfaces), originally described by Jack Lindamood [here](https://medium.com/@cep21/preemptive-interface-anti-pattern-in-go-54c18ac0668a) and [here](https://medium.com/@cep21/what-accept-interfaces-return-structs-means-in-go-2fe879e25ee8), has been a formal proverb of the Go community for a bit over [2 years now](https://github.com/golang/go/wiki/CodeReviewComments/88f0e01cb090f88fe0639268076e6b3fddac0601). Both Jack and the official proverb list different intents and motivations; let's break them down:

### Go CodeReviewComments:

> Go interfaces generally belong in the package that uses values of the interface type, not the package that implements those values. The implementing package should return concrete (usually pointer or struct) types: that way, new methods can be added to implementations without requiring extensive refactoring.
> 
> Do not define interfaces on the implementor side of an API "for mocking"; instead, design the API so that it can be tested using the public API of the real implementation.
> 
> Do not define interfaces before they are used: without a realistic example of usage, it is too difficult to see whether an interface is even necessary, let alone what methods it ought to contain.

Points of interest:

* New methods can be added to implementations without requiring extensive refactoring
* Design the API so that it can be tested using the public API of the real implementation
* Do not define interfaces before they are used

### Jack Lindamood:

> the Preemptive Interface pattern [is] often used in code and [...] I think it is generally an incorrect pattern to follow in Go.

> Preemptive interfaces are when a developer codes to an interface before an actual need arrises.

> Preemptive interfaces are often used with much success in Java, which is where I believe most Go programmers get the idea that it is also good practice in Go. The driving difference that makes this not true is that Java has explicit interfaces while Go has implicit interfaces.

> Go is at its most powerful when interface definitions are small. 

> Accepting interfaces gives your API the greatest flexibility and returning structs allows the people reading your code to quickly navigate to the correct function.

> Even if your Go code accepts structs and returns structs to start, implicit interfaces allow you to later broaden your API without breaking backwards compatibility. Interfaces are an abstraction and abstraction is sometimes useful. However, unnecessary abstraction creates unnecessary complication. Don’t over complicate code until it’s needed.

> The crux of the idea, and understanding when to bend it, is in the balance of avoiding preemptive abstractions while maintaining flexibility.

> Preemptive abstractions make systems complex

> This isn’t needed with Go because of implicit interfaces. The public functions of the returned struct become that API.

> Some languages require you to foresee every interface you’ll ever need.

> A great advantage of implicit interfaces is that they allow graceful abstraction after the fact without requiring you to abstract up front.

> This imbalance between being able to precisely control the output, but be unable to anticipate the user’s input, creates a stronger bias for abstraction on the input than it does on the output.
