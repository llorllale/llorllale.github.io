---
layout: post
title: Java's equals()/hashCode()
excerpt: How equals() and hashCode() would've looked like if we had had union of generic types in Java since day one.
date: 2017-10-08
author: George Aristy
tags:
- java
- OOP
- equals
- hashcode
---

One of my pet peeves of the `Object.equals()` and `Object.hashCode()` implementations that every class inherits in Java is the fact that, in principle, these are *really intimate* concerns of the class implementation, and that `Object`, a class that can be far removed from a user-defined type, should not be dictating what *equality* means to a descendant.

I mean, if I had to guess, I'd say that James Gosling, creator of the Java programming language, was already [righteously] thinking of collections when designing Java, but gave **no** thought to *union types*.

### Enter union types
It turns out that since generics were first introduced in Java, [union of types](https://stackoverflow.com/a/42686/1623885) has been supported! Consider this example:

{% highlight java %}
public interface Intersection<T extends Number & Comparable<T>> {
  public default int doSomething(T t1, T t2) {
    return t1.compareTo(t2) + t1.byteValue();
  }
}
{% endhighlight %}

Pay attention to the implementation of `doSomething`: `t1` holds methods of both `Comparable` and `Number`!

Having learned all this, I believe if Java had supported `union types` when it introduced `Object.equals()` and `Object.hashCode()`, then logically the latter two should have been introduced in their own two interfaces, perhaps `Equality<T>` and `Hashcode` respectively.

But first:

#### Reference equality
Java already provides the `==` operator, otherwise known as the `reference equality` operator. That is, if two references, `X` and `Y`, point to the same object in the heap, then `X == Y` will equal `true`.

#### Object.hashCode()
The default implementation of `Object.hashCode()` is a native method call that ["typically ... [converts] the internal address of the object into an integer"](http://grepcode.com/file/repository.grepcode.com/java/root/jdk/openjdk/6-b27/java/lang/Object.java#Object.hashCode()).

#### Object.equals()
The default implementation of `Object.equals()` is precisely a [reference comparison](http://grepcode.com/file/repository.grepcode.com/java/root/jdk/openjdk/6-b27/java/lang/Object.java#Object.equals(java.lang.Object))!

{% highlight java %}
public boolean equals(Object other) {
  return this == other;
}
{% endhighlight %}

In other words, whoever needs to perform the default "equality comparison" on an object already has the `==` operator at his disposal - no API contract required! Moreover, this violates the aforementioned principle, elegantly exposed by Brian Goetz - current Java language architect - while responding to a [related inquiry](http://mail.openjdk.java.net/pipermail/lambda-dev/2013-March/008435.html):

    The decision about equals/hashCode behavior is so fundamental that it 
    should belong to the writer of the class, at the time the class is first 
    written...

This is another reason why `equals()` and `hashCode()` are best left as interface contracts to be implemented in classes, eg.: 

{% highlight java %}
//assume the declaration for Equality was legal in Java
public interface Equality<T> {
  public boolean equals(T other);
}

public interface HashCode {
  public int code();
}
{% endhighlight %}

... and any code with requirements on the equality or hashCode amongst instances of the types it accepts should really declare its *intent* via its API, eg.:

{% highlight java %}
public interface Map<K extends Equality<K> & HashCode, V> {
  public V get(K key);
}
{% endhighlight %}

**[EDIT 2017-11-05]**

Reading back on this as I prepare my post on the new 'data class' proposal in project amber, I realized that the above interface proposals can be improved a bit:

Analyzing the [equals()](https://docs.oracle.com/javase/9/docs/api/java/lang/Object.html#equals-java.lang.Object-) vs. the [hashCode()](https://docs.oracle.com/javase/9/docs/api/java/lang/Object.html#hashCode--) contracts, it becomes obvious that despite mention of `hashCode()` in the `equals()` javadoc, the latter's implementation *does not depend on the former's*. However, `hashCode()` **does** make demands of `equals()`. Therefore, I amend my interface proposal to:

{% highlight java %}
public interface Equality<T> {
  public boolean equals(T other);
}

/**
 * Specifications for the requisites on Equality#equals
 */
public interface HashCode<T> extends Equality<T> {
  public int code();
}

//and Map's declaration would clear up a bit
public interface Map<K extends HashCode<K>, V> {
  public V get(K key);
}
{% endhighlight %}

It is now clear that a) `equality` does not require an object to be *hashable*, and b) `hashCode` is a separate concern intended to improve performance of *some* collections that require `Equality#equals` to behave a certain way in order for those collections to behave properly.
