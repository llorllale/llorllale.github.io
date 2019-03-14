---
layout: post
title: Golang - Smarter containers
excerpt: One riddle solved, but <code>range</code> keeps holding us back.
date: 2019-03-13
author: George Aristy
tags:
- go
- golang
- learning-go
- elegant-objects
---

*This post is part of a [series](https://llorllale.github.io/tags/#learning-go) where I do my best to organize my thoughts around Go: its paradigms and usability as a programming language. I write this as a Java programmer that respects the principles of [Elegant Objects](https://www.elegantobjects.org/).*

I wish to make a correction in [this](/golang-elegant-containers) post. I want to focus on this statement:

> `Products` is not a “smart” container - see point #3 in the Java proposal. You would have to manually append the newly-created `Product` to `Products`

What I meant is that clients would have to use it like this:

{% highlight go %}
prods := make(Products, 0)
p := prods.Create(10)
prods = append(prods, p)	// extra imperative code forced on the client to add the product to the container
{% endhighlight %}

Let's pay attention to this snippet:

{% highlight go %}
func (p *Products) Create(price float64) Product {
	prod := &product{id: 123, price: price}
	tmp := append(*p, prod) // compiler would not allow p = &(append(*p, prod))
	p = &tmp                // the problem here is that the caller still retains the original handle to `p`
	return prod
}
{% endhighlight %}

I was *really* close to solving that riddle. The trick is to *assign a new value to the pointer variable*. The pointer variable itself is passed by value, so callers would also see the side effects. Here's what I mean:

{% highlight go %}
func (p *Products) Create(price float64) *Product {
	prod := &product{price: Price}
	*p := append(*p, prod) // done in one line for brevity
	return prod
}

// A test like this would pass
func TestCreate(t *testing.T) {
	prods := make(Products, 0)
	prod := prods.Create(10)
	assert.Len(t, prods, 1)
	assert.Contains(t, prods, prod)
}
{% endhighlight %}

With this I've proved that `Products` can be made smarter: create products and dynamically append them to itself.

Several problems remain:
* Slices don't know how to iterate themselves - only `range` knows that. Since this power is taken away from developers, iteration of `Products` is only possible with objects in memory. You cannot implement a custom iterable - like in Java - that can dynamically fetch results from a datasource.
* Since iteration is only done in memory space, deferred execution is harder to pull off. You'd basically need an abstraction for a function that returns the actual slice (think `type Products func() []Product`)
* Cannot be decorated. Cannot implement `Premium` as a slice of products because the type will have no usable attribute for this. Unless... we go back the function abstraction idea...
