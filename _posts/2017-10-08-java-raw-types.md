---
layout: post
title: Java Raw Types
excerpt: Java generic type erasure on ALL instance fields, not just those tied to the type parameter in the class declaration.
author: George Aristy
date: '2017-10-08T13:03:00.000-04:00'
categories:
  - programming
  - java
tags:
- bugs
- software-development
- java
- maven
- generics
comments: true
---

I was recently confounded by a something unexpected in Java's type-erasure. Consider the following snippets:

{% highlight java %}
public class Issue<T> {
  public List<String> list() {
    /* return a list */
  }
}
{% endhighlight %}

{% highlight java %}
public static void main(String... args) {
  final Issue issue = new Issue();        //notice the use of the raw type
  final String s = issue.list().get(0);   //DOES NOT COMPILE
}
{% endhighlight %}

It turns out that all generic type information is erased from an instance of a raw type - *including* all [instance methods and non-static fields](https://docs.oracle.com/javase/specs/jls/se8/html/jls-4.html#jls-4.8) that have nothing to do with the type parameter declared in the class declaration. In the example above, `issue.list()` returns a *raw* `List` from which you can't extract a `String`.

Getting around this limitation depends on your context. If the calling code has the option of defining the type parameter at runtime, then the fix is as easy as `final Issue<?> issue = new Issue<>(); final String s = issue.list().get(0);`. My situation was different though: due to an internal implementation detail, my interface's generic type declaration leaked out into its public API, even though it was never my intention for the calling code to be able to provide implementations of my interface. My final solution was getting rid of the generic type declaration entirely, albeit at the cost of a less-than-perfect separation of concerns in my internal implementation.

Why does Java behave this way? "Backwards-compatibility issues". ¯\\\_(ツ)\_/¯
