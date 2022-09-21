---
layout: post
title: "Golang Guild Session: Deadlocks (and how to break out of them)"
date: 2022-09-21 15:00:00 -0400
author: George Aristy
categories:
- talks
- golang
tags:
- go
- golang
- goroutine
- concurrency
- deadlock
---

Slide deck for my presentation on [Deadlocks](https://en.wikipedia.org/wiki/Deadlock) in Go for the _Golang Guild Session_ @ VerticalScope.

This talk extends my previous slides on [Golang Concurrency Patterns](/posts/golang-concurrency-patterns).

<iframe id="talk" width="800" height="400" src="/talks/golang-deadlocks.html">
  <p>Your browser does not support iframes.</p>
</iframe>

Click on the slide deck then press `F` to expand to full screen.

## Topics

<ul>
    <li><i style="color: lightgreen" class="fa fa-plus"></i> What deadlocks are</li>
    <li><i style="color: lightgreen" class="fa fa-plus"></i> When deadlocks typically happen</li>
    <li><i style="color: lightgreen" class="fa fa-plus"></i> How Go's runtime detects deadlocks</li>
    <li><i style="color: lightgreen" class="fa fa-plus"></i> Go's stacktraces</li>
    <li><i style="color: lightgreen" class="fa fa-plus"></i> Tools</li>
</ul>

## References

* [The Go Memory Model](https://go.dev/ref/mem)
* [Scalable Go Scheduler Design Doc](https://docs.google.com/document/d/1TTj4T2JO42uD5ID9e89oa0sLKhJYD0Y_kqxDv3I3XMw)
