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
- TODO Outdated?
  - converting arrays to slices (p46)
