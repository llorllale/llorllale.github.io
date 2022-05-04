---
layout: post
title: "Golang Guild Session: Concurrency Primitives"
date: 2022-05-04 10:00:00 -0400
author: George Aristy
categories:
- talks
- golang
tags:
- go
- golang
- scheduler
- goroutine
- mutexes
- channels
- concurrency
---

Slide deck for my presentation on Golang Concurrency Primitives for the _Golang Guild Session_ @ VerticalScope.

<iframe id="talk" width="800" height="400" src="/talks/golang-concurrency-primitives.html">
  <p>Your browser does not support iframes.</p>
</iframe>

Click on the slide deck then press `F` to expand to full screen.

## Topics

* goroutines
* channels
* sync.WaitGroup
* sync.Once
* mutexes
* extra:
  * sync/atomic
  * sync.Map
  * errgroup.Group

## References

* [The Go Programming Language Specification](https://go.dev/ref/spec)
* [Learning Go: An Idiomatic Approach to Real-World Go Programming](https://www.amazon.ca/Learning-Go-Idiomatic-Real-World-Programming/dp/1492077216)
* [YouTube: The Scheduler Saga](https://www.youtube.com/watch?v=YHRO5WQGh0k)
