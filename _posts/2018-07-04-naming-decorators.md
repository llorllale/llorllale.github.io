---
layout: post
title: Nominalized Adjectives as Names for Decorators
excerpt: Use nominalized adjectives as names for your decorators for terser code.
date: '2018-07-05T10:17:00.001-04:00'
author: George Aristy
tags:
- decorators
- oop
---

There is a strong tendency among Java and C# programmers to prefix or suffix their extended types,
such as naming a "smart" `View` as [`SmartView`](https://github.com/spring-projects/spring-framework/blob/master/spring-webmvc/src/main/java/org/springframework/web/servlet/SmartView.java),
or a `Work` that is "delegated" as [`DelegatingWork`](https://github.com/spring-projects/spring-framework/blob/master/spring-context-support/src/main/java/org/springframework/scheduling/commonj/DelegatingWork.java).
In this post I will focus on [decorators](https://en.wikipedia.org/wiki/Decorator_pattern) and how this
widespread naming scheme reduces readability and adds no value to the code's context. I think it's
time we retire this needless naming redundancy.

<div style="text-align:center">
  <img src="/assets/img/office-space-milton.jpg" alt="Milton"/><br/>
  <small>Milton, from <a href="https://www.imdb.com/title/tt0151804/">Office Space</a></small>
</div>

[Composable decorators](https://www.yegor256.com/2015/02/26/composable-decorators.html) are small,
highly cohesive objects that work off of another instance of their same type and thus are unable to
function on their own. You can think of decorators as **adjectives**.

{% highlight java %}
  final Collection<Product> products = new FilteredCollection<>(
      Product::active,
      new MappedCollection<>(
          Subscription::product,
          new JoinedCollection<>(
              subscriptions1,
              subscriptions2,
              ...
          )
      )
  );
{% endhighlight %}

The problem with the traditional naming scheme is the needless repetition: we know from the outset
that `products` is a `Collection` but the code keeps hammering this point home over and over again
as we read on. This code is tedious to write, but more importantly, it is tedious to *read*,
because of how the **words** are composed:

> 'product' is a filtered collection, a mapped collection, a joined collection, collection

Normal, every day speech is not encumbered like this; nouns are routinely omitted when sufficient
meaning can be extracted from the context. You don't normally say `The rich people and the poor
people`, you just say `the rich and the poor`. **Nouns** are *omitted* and **adjectives** are
*[nominalized](https://en.wikipedia.org/wiki/Nominalized_adjective)*.

Following this same principle, to make the code above read like this:

> 'product' is a filtered, mapped, joined collection

It would have to look like this:

{% highlight java %}
  final Collection<Product> products = new Filtered<>(
      Product::active,
      new Mapped<>(
          Subscription::product,
          new Joined<>(
              subscriptions1,
              subscriptions2,
              ...
          )
      )
  );
{% endhighlight %}

I recommend we make our code terser by removing redundancy and allowing the code's context to work
in our favor for readability's sake. For example, let's use nominalized adjectives as names for our
decorators.

