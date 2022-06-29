---
layout: post
title: "Golang Guild Session: Concurrency Patterns"
date: 2022-06-29 15:30:00 -0400
author: George Aristy
categories:
- talks
- golang
tags:
- go
- golang
- goroutine
- mutexes
- channels
- concurrency
- pattern
---

Slide deck for my presentation on Golang Concurrency Patterns for the _Golang Guild Session_ @ VerticalScope.

This talk builds upon my previous slides on [Golang Concurrency Primitives](/posts/golang-concurrency-primitives).

<iframe id="talk" width="800" height="400" src="/talks/golang-concurrency-patterns.html">
  <p>Your browser does not support iframes.</p>
</iframe>

Click on the slide deck then press `F` to expand to full screen.

## Topics

<ul>
    <li><i style="color: lightgreen" class="fa fa-plus"></i> The Done channel pattern</li>
    <li><i style="color: lightgreen" class="fa fa-plus"></i> The Fan-In pattern</li>
    <li><i style="color: lightgreen" class="fa fa-plus"></i> The Fan-Out pattern</li>
    <li><i style="color: lightgreen" class="fa fa-plus"></i> Sharding</li>
    <li><i style="color: lightgreen" class="fa fa-plus"></i> Bounded Parallelism</li>
    <li><i style="color: lightgreen" class="fa fa-plus"></i> Backpressure</li>
    <li><i style="color: red" class="fa fa-minus"></i> Deadlocks <span>(stay tuned)</span></li>
</ul>

## References

* [Learning Go: An Idiomatic Approach to Real-World Go Programming](https://www.amazon.ca/Learning-Go-Idiomatic-Real-World-Programming/dp/1492077216)
* [Cloud-Native Go: Building Reliable Services in Unreliable Environments](https://www.amazon.ca/Cloud-Native-Go-Unreliable-Environments/dp/1492076333)
* [The Go Blog: Go Concurrency Patterns: Pipelines and cancellation](https://go.dev/blog/pipelines)
