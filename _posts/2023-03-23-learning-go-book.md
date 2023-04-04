---
layout: post
title: "Learning Go: An Idiomatic Approach to Real-World Go Programming"
date: 2023-03-11 10:00:00 -0500
author: George Aristy
categories:
- books
- golang
tags:
- book
- go
- golang
---

![book cover](/assets/img/books/learning-go/front-cover.jpg){: .left height="300" width="200" }
Written by [Jon Bodner](https://www.linkedin.com/in/jonbodner/), 
[Learning Go: An Idiomatic Approach to Real-World Go Programming](https://www.amazon.ca/Learning-Go-Idiomatic-Real-World-Programming/dp/1492077216)


- Pros:
  - teaches idioms
    - short bodies for `if`, as left-aligned as possible
  - starts at the basics of tooling, basic data types, then slowly progresses to more complicated subjects (TODO)
  - uses coding examples
  - encourages and shows how to use linters to catch common bugs (eg. p64 shadow linter)

- idioms
  - comma-OK
  - map as set
  - "types are executable documentation" (p136). I recently suggested someone create a functional `Option` type to
    improve readability
  - grrr "accept interfaces, return structs" (p146)

- TODO things I learned:
  - support for complex numbers! (p24)
  - a slice taken from a slice shares the same backing array (p44-45)
  - strings and runes and bytes (p48,74)
  - struct conversion (p59)
  - accidentally shadowing variables with := in multiple assignments (p63)
  - the universe block (and what I thought were keywords but really are not) (p65)
  - blank switch (p81)
  - (relearn) pointers indicate mutable parameters (p113)
  - pointer passing performance (p118)
  - why we pass buffers to io.CopyBuffer: to avoid unnecessary memory allocations (p122-123)
  - reducing the GC's workload (p123)
  - Go considers both pointer and value receiver methods to be in the method set for a pointer instance. For a value instance, 
    only the value receiver methods are in the method set. (p132)
  - iota (p137)
  - no dynamic dispatch (p140)
  - Invoking a function with args of type interface will result in a heap allocation for each of the interface types (p147)
  - interfaces and nil (p147)
  - function types as a bridge to interfaces (p154)
  - aliases versus types? (p189)
  - using `go list` and `go get` to upgrade or downgrade dependency versions
  - How channels behave (p209)
  - writing to channels in a `select` `case` (p211)
  - nuances on how `select` works - seems like the cases are evaluated and then "materialized" if they aren't blocked,
    otherwise they don't have any effects. See example in p211. The first case, `case ch2 <- v` is never realized because
    the other case is executed first. The sub goroutine is stuck "forever" (until the main goroutine ends)
  - buffered, unbuffered channels, and backpressure (p217-218)
  - how to time out code (p219). refer to time.After vs Context.Done()
  - sync.Map - this is not the map you are looking for (p230)
  - reason why Go implements monotonic time (p240)
  - json.NewDecoder can decode multiple values (p245). Also I think it only reads just enough bytes (maybe slightly more) to decode a single type
  - we shouldn't use the static functions of `http` package because other packages may have registered their own handlers
    in the default serve mux. "keep your application under control by avoiding shared state" (p251)
  - http.StripPrefix (p251)
  - limit number of queued requests with buffered channels and a `select` (p262)
  - "empty struct uses no memory" (p263)
  - benchmarks! (p283)
  - "short tests" (p295)
  - use reflect to make functions and structs (p312-313)
  - performance boost when using unsafe.Pointer (p317-319)

- TODO Outdated?
  - converting arrays to slices (p46)

- errata
  - "goroutines are lightweight processes" (p205). refer to my own talk on the subject