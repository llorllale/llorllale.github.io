---
layout: post
title: My Naming Preference for Extended Types and Decorators
excerpt: Avoid unnecessary noise and use nominalized past participles.
date: '2018-07-04T10:17:00.001-04:00'
author: George Aristy
tags:
- decorators
- oop
---

There is a strong tendency among Java and C# programmers to prefix or suffix their extended types, such as naming a "smart" `View` as [`SmartView`](https://github.com/spring-projects/spring-framework/blob/master/spring-webmvc/src/main/java/org/springframework/web/servlet/SmartView.java), or a `Work` that is "delegated" as [`DelegatingWork`](https://github.com/spring-projects/spring-framework/blob/master/spring-context-support/src/main/java/org/springframework/scheduling/commonj/DelegatingWork.java). The problem here is that all these prefixes and suffixes are just noise that do not add value to their context. I believe it is time we retire this redundant practice.

<div style="text-align:center"><img src="/assets/images/office-space-milton.jpg" alt="Milton"/></div>

The redundancy is especially evident when using [decorators](https://www.yegor256.com/2015/02/26/composable-decorators.html):

{% highlight java %}
  final Collection<Products> products = ...;
  final Collection<Products> active = 
{% endhighlight %}

