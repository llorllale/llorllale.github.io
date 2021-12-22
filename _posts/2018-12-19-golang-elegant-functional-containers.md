---
layout: post
title: Golang - another go at elegant containers
excerpt: Improvement over initial attempt by adopting a bit of a functional programming paradigm.
date: 2018-12-19
author: George Aristy
tags:
- go
- golang
- learning-go
- elegant-objects
---

*This post is part of a [series](/tags/learning-go) where I do my best to organize my thoughts around Go: its paradigms and usability as a programming language. I write this as a Java programmer that respects the principles of [Elegant Objects](https://www.elegantobjects.org/).*

In a [previous post](/posts/golang-elegant-containers) I attempted to implement Elegant container-like idioms in *Go*. My approach was straightforward: follow the same train of thoughts I do in Java. I failed miserably.

Following is an approach I find interesting.

## Let's use Functions

Let's ditch interfaces altogether and define our `Products` type as a function. I've managed to earn back two features of the Java counterpart:

1. Actual decorators
2. Deferred execution

**However**, I've only managed to work it out for *query* capabilities. Our `Products` is still a *castrated object* because it lacks smart capabilities as per point #3 in the previous post.

{% highlight go %}
package products

type Product interface {
	Id() int
	Price() float64
}

type Products func() []Product

// function with a function as receiver!
func (p Products) Fetch(id int) Product {
	for _, prod := range p() {
		if prod.Id() == id {
			return prod
		}
	}
	return nil
}

// all products
func All() Products {
	// read from a database, etc.
	return nil
}

// premium products filtered by `minimum` price
func Premium(minimum float64, all Products) Products {
	return func() []Product {
		filtered := make([]Product, 0)
		for _, p := range all() {
			if p.Price() >= minimum {
				filtered = append(filtered, p)
			}
		}
		return filtered
	}
}

// USAGE
func main() {
	premium := products.Premium(1000, products.All())
	prod := premium.Fetch(123) // fetch one premium product
	fmt.Printf("%+v", prod)
	for _, p := range premium() { // iterate through all premium products
		fmt.Printf("%+v", p)
	}
}
{% endhighlight %}

## Conclusion

A bit early to actually reach a conclusion but this design further encourages me to believe that *Go* is a lot more oriented towards functional programming than object-oriented programming. Almost to the pointing of making me question what net value do interfaces in this language provide?
