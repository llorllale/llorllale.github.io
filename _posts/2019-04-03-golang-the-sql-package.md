---
layout: post
title: Golang - The database/sql package
excerpt: TLDR - database/sql eases the learning curve for users by providing a simple API that nevertheless breaks the single responsibility principle and incorporates orthogonal yet useful functionality into this package.
date: 2019-04-03
author: George Aristy
image:
  src: /assets/img/gopher_peek.png
  alt: gopher
tags:
- go
- golang
- learning-go
- go-proverbs
---

*This post is part of a [series](/tags/learning-go) where I do my best to organize my thoughts around Go: its paradigms and usability as a programming language. I write this as a Java programmer that respects the principles of [Elegant Objects](https://www.elegantobjects.org/).*

I am studying the Go Code Review mantra [*Accept Interfaces, Return Structs*](https://github.com/golang/go/wiki/CodeReviewComments#interfaces) and was inspired to write this post after coming across Eli Bendersky's post [Design patterns in Go's database/sql package](https://eli.thegreenplace.net/2019/design-patterns-in-gos-databasesql-package/). This is the first instance where I feel I can endorse the mantra with confidence. Eli does a good job analysing the architecture of `database/sql` - I'm just here to provide a little nuance and some of my own notes.

## Problem statement

Application programmers need a [Database abstraction layer](https://en.wikipedia.org/wiki/Database_abstraction_layer) over a variety of SQL or SQL-like datasources for the most common use cases.
{: .notice}

Designing DALs is hard for two primary reasons:

* The large variety of database implementations and drivers
* The large variety of common use cases
  * CRUD
  * Transactions
  * Connection pooling
  * Prepared Statements
  * Mapping of data types
  * Stored procedures and functions

Any solution is bound to end up as fat APIs ala [`sql.DB`](https://golang.org/pkg/database/sql/#DB) or [`JDBC`](https://docs.oracle.com/en/java/javase/11/docs/api/java.sql/java/sql/package-summary.html).

## database/sql.DB

Interestingly, [`sql.DB`](https://golang.org/pkg/database/sql/#DB) is a concrete type, not an interface. *Why?*

`sql.DB` exposes a fat interface for the reasons laid out in [Problem statement](#problem-statement). There are several strategies to limit an API's *obesity*[<sup>1</sup>](#note1) - both `database/sql` and `JDBC` opt for the [Interface Segregation Principle](https://en.wikipedia.org/wiki/Interface_segregation_principle). `database/sql` muddles the waters a bit by doing [More Than One Thing](https://en.wikipedia.org/wiki/Single_responsibility_principle), while `JDBC` offers a cleaner separation of concerns.

**Because `sql.DB` is *necessarily* fat[<sup>2</sup>](#note2)<sup>,</sup>[<sup>3</sup>](#note3), making it an interface will only hinder code that depends on it**: it's painful and wasteful to have to implement all those methods in your production code and in your mocks when you only need 3 or 4. For these reasons, programmers in general prefer to design [*facades*](https://en.wikipedia.org/wiki/Facade_pattern) or [*adapters*](https://en.wikipedia.org/wiki/Adapter_pattern) and place them in front[<sup>4</sup>](#note3) of fat APIs. Both in Java and in Go this extra component can be either a concrete type or an abstract type.

[YAGNI](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it): whether you use a concrete or an abstract type depends on whether you'll actually need the extra level of abstraction.
{: .notice}

## Decoupling the user interface from driver interface

Regarding *why* `database/sql` split the user interface `sql.DB` from `driver.Driver`, Eli notes:

> 1. Adding user-facing capabilities is difficult because they may require adding methods to the interface. This breaks all the interface implementations and requires multiple standalone projects to update their code.
> 2. Encapsulating functionality that is common to all database backends is difficult, because there is no natural place to add it if the user interacts directly with the DB interface. It has to be implemented separately for each backend, which is wasteful and logistically complicated.
> 3. If backends want to add optional capabilities, this is challenging with a single interface without resorting to type-casts for specific backends.

These points are true, but I think the overarching theme behind this design decision is *simplicity and ease of use*. Proper interface segregation and separation of concerns[<sup>5</sup>](#note5) took the back seat and it all led to a mix of several orthogonal requirements in a single interface:

* Execute queries
* Connection pooling
* Thread safety

They decided to implement Connection Pooling and Thread Safety themselves while drivers need only provide connections (and statements, and everything else derived from connections).

The upside of this clear violation of SRP[<sup>6</sup>](#note6) is a simpler learning curve for the user (they are exposed to a single, simple interface) and a simpler driver interface for vendors to implement.

The downside is that the maintainers are burdened with the maintenance of code that doesn't necessarily meet all user's needs and may be stifling innovation in this area for Golang[<sup>7</sup>](#note7).

## Conclusion

`database/sql` eases the learning curve for users by providing a simple API that nevertheless breaks the single responsibility principle and incorporates orthogonal yet useful functionality into this package, potentially discouraging innovation.

`sql.DB` is presented best as a concrete type and not an interface because its requirements *necessarily* inflate it into a fat API, greatly diminishing any returns an interface has in a structurally-typed language like Go.

<br/><br/><br/>

-----

<span id="note1"><sup>1</sup></span> aka "surface area", but hey - since we're talking about "Fat APIs" we might as well run with it :)

<span id="note2"><sup>2</sup></span> justifiably breaking the [Go Proverb](https://go-proverbs.github.io/) *The bigger the interface, the weaker the abstraction*

<span id="note3"><sup>3</sup></span> see section 2.9 of [Elegant Objects vol 1](https://www.amazon.ca/Elegant-Objects-Yegor-Bugayenko/dp/1519166915) *Keep interfaces short; use smarts* 

<span id="note4"><sup>4</sup></span> aka "wrap", but I dislike the term because its meaning has been diluted and may refer to any one of several distinct patterns

<span id="note5"><sup>5</sup></span> see design parameters for `database/sql`[here](https://raw.githubusercontent.com/golang/go/master/src/database/sql/doc.txt)

<span id="note6"><sup>6</sup></span> [Single Responsibility Principle](https://en.wikipedia.org/wiki/Single_responsibility_principle)

<span id="note7"><sup>7</sup></span> consider the wide variety of database-connection-pooling libraries in the Java ecosystem and how they each emphasize different aspects like ease of use, performance, features, etc.

<span id="note8"><sup>8</sup></span> see "slow builds" and "uncontrolled dependencies" in section 4 *Pain Points* of Rob Pike's [Go at Google: Language Design in the Service of Software Engineering](https://talks.golang.org/2012/splash.article)
