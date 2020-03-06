---
layout: post
title: Golang - are Elegant Containers possible?
excerpt: TLDR doesn't seem like it.
date: 2018-12-19
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

    // overridden
    public Optional<Product> fetch(Long id) {
        return this.all.fetch(id).filter(prod -> prod.price() >= MINIMUM);
    }

    // overridden
    public Product create(Float price) {
        if (price < MINIMUM) {
            throw new IllegalArgumentException();
        }
        return this.all.create(price);
    }

    // overridden
    public Iterator<Product> iterator() {
        return new Filtered<>(		// org.cactoos.iterator.Filtered
            prod -> prod.price() >= MINIMUM,
            this.all.iterator()
        );
    }
}
```

This design has several interesting properties:

1. `Products` can be iterated over in a `for-each` loop
2. The semantics of "`Products` IS-A `Iterable<Product>`" just works
3. Any `Product` created will be viewable in a subsequent `for-each` traversal
4. High cohesion: `AllProducts` focuses on all products, while `Premium` focuses on enforcing premium pricing rules.
5. Any `Iterable<Product>` can be decorated with another `Iterable<Product>`
6. Iteration is lazily-evaluated

### Can it be done in Go?

**Elephant in the room:** `range` only works on arrays and slices (those two are the only applicable types within scope of this blog post). That's right: unlike in Java, canonical *for-each* loops in *Go* can only be done against arrays or slices, instead of against an interface. This immediately negates several points above.

Not iterating against an interface means decorators lose the ability to lazyily evaluate the decorated object. This has implications for performance.
{: .notice}

However way you slice it, any "iterable" decorators will have to preload the entire decorated array and operate on that.

So, barring that, how would this all look like in *Go*?

```go
type Product interface {
	Id() int
	Price() float64
}

// Our "elegant" container. Notice this type doesn't implement an interface.
type Products []Product

func (p *Products) Create(price float64) Product {
	prod := &product{id: 123, price: price}
	tmp := append(*p, prod) // compiler would not allow p = &(append(*p, prod))
	p = &tmp                // the problem here is that the caller still retains the original handle to `p`
	return prod
}

func (p *Products) Fetch(id int) Product {
	for _, prod := range *p {
		if prod.Id() == id {
			return prod
		}
	}
	// idiomatic Go signals "not found" using `nil`
	return nil
}

// Our "decorator". Notice this is a completely different type than `Products`
type Premium struct {
	Products
	threshold float64
}

func (p *Premium) Fetch(id int) Product {
	prod := p.Products.Fetch(id)
	if prod != nil && prod.Price() >= p.threshold {
		return prod
	}
	return nil
}

func (p *Premium) Create(price float64) Product {
	if price < p.threshold {
		panic("illegal price")
	}
	return p.Products.Create(price)
}
```

There are a couple of problems here;

1. `Products` is not a "smart" container - see point #3 in the Java proposal. You would have to manually `append` the newly-created `Product` to `Products`
2. `Premium` is **NOT** a `Products`:
```go
func Test(t *testing.T) {
	prods := make(Products, 0)
	test(prods)
	premium := Premium{Products: prods, threshold: 1000}
	test(premium) 	// compiler error: cannot use premium (type Premium) as type Products
}
```
