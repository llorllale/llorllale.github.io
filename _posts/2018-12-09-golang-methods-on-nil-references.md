---
layout: post
title: Golang - methods on nil references
excerpt: I don't know what good methods on nil references are for.
date: '2018-12-09T15:00:00.000-05:00'
author: George Aristy
feature: assets/images/all-animals-are-equal.jpg
tags:
- go
- golang
- null-object-pattern
- nil
- learning-go
---

*This is the first post in a series in which I do my best to organize my thoughts around Go: its paradigms and usability as a programming language. I write this as a Java programmer that respects the principles of [Elegant Objects](https://www.elegantobjects.org/).*

[Go](https://golang.org/) has structs - which are essentially [DTOs](https://en.wikipedia.org/wiki/Data_transfer_object) - and the ability to implement methods on these structs by specifying [receivers](https://tour.golang.org/methods/1) on functions.

Go allows one to call methods on `nil` references because, although functions and structs are both equally first-class citizens, *functions are more equal than structs* (hence this post's feature image).

## What are methods on `nil` references good for?

Consider this API:

{% highlight go %}
package people

type Person interface {
	Name() string
}

// GetPerson returns nil indicating the person was not found
func GetPerson(name string) Person {
	return nil
}

type person struct {
	name string
}

func (p *person) Name() string {
	return p.name
}	
{% endhighlight %}

Our **test code** will panic if `nil` is returned by `GetPerson()`:

{% highlight go %}
	person := GetPerson()
	fmt.Print(person.Name()) 	// panic: invalid memory address or nil pointer dereference
{% endhighlight %}

There are several ways the API can be improved in order to signal that this person was not found; I'm not sure which one is more idiomatic in *Go*. Let's consider implementing the [Null Object Pattern](https://en.wikipedia.org/wiki/Null_object_pattern) by exploiting the fact that you can execute methods on `nil` references.

Let's modify the `Name()` implementation on our `person` struct:

{% highlight go %}
func (p *person) Name() string {
	if p == nil {
		return "person was not found"
	}
	return p.name
}
{% endhighlight %}

Our **test code** will now print `person was not found`.

Now `Person` has a dual nature: depending on circumstances, it can be a normal person with a name, or it can be an "invalid" person. This is an additional cognitive burden when trying to understand this struct. `person` is now **unfocused**, breaking the [Single Responsibility Principle](https://en.wikipedia.org/wiki/Single_responsibility_principle).

**I don't know what good methods on nil references are for.**
{: .notice}

