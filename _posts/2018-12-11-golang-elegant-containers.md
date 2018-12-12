---
layout: post
title: Golang - are Elegant Containers possible?
excerpt: Nope.
date: 2018-12-11
author: George Aristy
tags:
- go
- golang
- learning-go
- elegant-objects
---

*This post is part of a [series](https://llorllale.github.io/tags/#learning-go) where I do my best to organize my thoughts around Go: its paradigms and usability as a programming language. I write this as a Java programmer that respects the principles of [Elegant Objects](https://www.elegantobjects.org/).*

## What are "Elegant Containers"?

[*EO style*](https://www.elegantobjects.org/) containers maximize the reuse of the highest abstractions possible, do not add unnecessary attributes or "getters", and earn our respect because they [know how to do their job](https://martinfowler.com/bliki/TellDontAsk.html).

## Scenario

We need to create and fetch products. We also need to segregate products into regular and premium classes. Premium products cannot be priced below $1000.

### Java Example

```java
public interface Products extends Iterable<Product> {
	Optional<Product> fetch(Long id);
	Product create(Float price);
}

public final class AllProducts implements Products {
	...
}

public final class Premium implements Products {
  private static final Float MINIMUM = 1000f;
  private final Products all;

  public Premium(Products all) {
    this.all = all;
  }

  @Override
  public Optional<Product> fetch(Long id) {
    return this.all.fetch(id);
  }

  @Override
  public Product create(Float price) {
    if (price.compareTo(Premium.MINIMUM) < 0) {
      throw new IllegalArgumentException();
    }
    return this.all.create(price);
  }

  @Override
  public Iterator<Product> iterator() {
		// using org.cactoos.iterator.Filtered
    return new Filtered<>(
      prod -> prod.price().compareTo(Premium.MINIMUM) >= 0,
      this.all.iterator()
    );
  }
}
```

This design has several interesting properties:

* `Products` can be iterated over in a `for-each` loop
* The semantics of "`Products` IS-A `Iterable<Product>`" works well
* Any `Product` created will be viewable in a subsequent `for-each` traversal
* High cohesion: `AllProducts` focuses on all products, while `Premium` focuses on enforcing premium pricing rules while reusing the generic iterator `org.cactoos.iterator.Filtered`
* Any `Iterator<Product>` can be decorated with another `Iterator<Product>`

### Can it be done in Go?

