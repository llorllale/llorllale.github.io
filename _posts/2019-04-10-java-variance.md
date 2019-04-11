---
layout: post
title: Variance in Java
excerpt: Complicated if required learning for an exam, but generally intuitive and useful in daily practice.
date: 2019-04-10
author: George Aristy
feature: http://www.oracle.com/us/technologies/java/gimmejava/i-code-java-300x352-1705306.png
tags:
- java
- variance
- generics
---

The other day I came across [this](http://onoffswitch.net/8-months/) post describing what the author sees as pros and cons of Go after 8 months of experience. I mostly agree after working full time with Go for a comparable duration. 

Despite that preamble, this is a post about Variance in **Java**, where my goal is to refresh my understanding of what Variance is and some of the nuances of its implementation in Java.

(*ProTip: You'll need to know this for your [OCJP](https://education.oracle.com/oracle-certified-professional-java-se-8-programmer/trackp_357) certificate exam.*)

I will write down my thoughts on this subject for Go in a later post.

## What is Variance?

The Wikipedia article on [*variance*](https://en.wikipedia.org/wiki/Covariance_and_contravariance_(computer_science)) says:

> **Variance** refers to how subtyping between more complex types relates to subtyping between their components.

"More complex types" here refers to higher level structures like containers and functions. So, variance is about the *assignment compatibility* between containers and functions composed of parameters that are connected via a [Type Hierarchy](https://en.wikipedia.org/wiki/Class_hierarchy). It allows the safe integration of parametric and subtype polymorphism[^1]. Eg. can I assign the result of a function that returns a list of cats to a variable of type "list of animals"? Can I pass in a list of Audi cars to a method that accepts a list of cars? Can I insert a wolf in this list of animals?

In Java, variance is defined at the **use-site**[^2].
{: .notice}

## 4 Kinds of Variance

Paraphrasing the wiki article, a type constructor is:

* **Covariant** if it accepts subtypes but not supertypes
* **Contravariant** if it accepts supertypes but not subtypes
* **Bivariant** if it accepts both supertypes and subtypes
* **Invariant** if does not accept neither supertypes nor subtypes

(Obviously the declared type parameter is accepted in all cases.)

## Invariance in Java

The use-site must have no open bounds on the type parameter.

If `A` is a supertype of `B`, then `GenericType<A>` is **not** a supertype of `GenericType<B>` and vice versa.
{: .notice}

This means these two types have no relation to each other and neither can be exchanged for the other under any circumstance.

### Invariant containers

In Java, invariants are likely the first examples of generics you'll encounter and are the most intuitive. The methods of the type parameter are useable as one would expect. All methods of the type parameter are accessible.

They cannot be exchanged:

{% highlight java %}
// Type hierarchy: Person :> Joe :> JoeJr
List<Person> p = new ArrayList<Joe>(); // COMPILE ERROR (a bit counterintuitive, but remember List<Person> is invariant)
List<Joe> j = new ArrayList<Person>(); // COMPILE ERROR
{% endhighlight %}

You can add objects to them:

{% highlight java %}
// Type hierarchy: Person :> Joe :> JoeJr
List<Person> p = new ArrayList<>();
p.add(new Person()); // ok
p.add(new Joe()); // ok
p.add(new JoeJr()); // ok
{% endhighlight %}

You can read objects from them:

{% highlight java %}
// Type hierarchy: Person :> Joe :> JoeJr
List<Joe> joes = new ArrayList<>();
Joe j = joes.get(0); // ok
Person p = joes.get(0); // ok
{% endhighlight %}

## Covariance in Java

The use-site must have an *open lower bound* on the type parameter.

If `B` is a subtype of `A`, then `GenericType<B>` is a subtype of `GenericType<? extends A>`.
{: .notice}

### Arrays in Java have always been covariant

Before generics were introduced in Java `1.5`, arrays were the only generic containers available. They have always been covariant, eg. `Integer[]` is a subtype of `Object[]`. The danger has always been that if you pass your `Integer[]` to a method that accepts `Object[]`, that method can literally put *anything* in there. It's a risk you take - not matter how small - when using third party code.

### Covariant containers

Java allows subtyping (covariant) generic types but it places restrictions on what can "flow into and out of" these generic types in accordance with the Principle of Least Astonishment[^3]. In other words, methods with return values of the type parameter are accessible, while methods with input arguments of the type parameter are inaccessible.

You can exchange the supertype for the subtype:

{% highlight java %}
// Type hierarchy: Person :> Joe :> JoeJr
List<? extends Joe> = new ArrayList<Joe>(); // ok
List<? extends Joe> = new ArrayList<JoeJr>(); // ok
List<? extends Joe> = new ArrayList<Person>(); // COMPILE ERROR
{% endhighlight %}

*Reading* from them is intuitive:

{% highlight java %}
// Type hierarchy: Person :> Joe :> JoeJr
List<? extends Joe> joes = new ArrayList<>();
Joe j = joes.get(0); // ok
Person p = joes.get(0); // ok
JoeJr jr = joes.get(0); // compile error (you don't know what subtype of Joe is in the list)
{% endhighlight %}

*Writing* to them is prohibited (counterintuitive) to guard against the pitfalls with arrays described [above](#arrays-in-java-have-always-been-covariant). Eg. in the example code below, the caller/owner of a `List<Joe>` would be *astonished* if someone else's method with covariant arg `List<? extends Person>` added a `Jill`.

{% highlight java %}
// Type hierarchy: Person > Joe > JoeJr
List<? extends Joe> joes = new ArrayList<>();
joes.add(new Joe());  // compile error (you don't know what subtype of Joe is in the list)
joes.add(new JoeJr()); // compile error (ditto)
joes.add(new Person()); // compile error (intuitive)
joes.add(new Object()); // compile error (intuitive)
{% endhighlight %}

## Contravariance in Java

The use-site must have an open **upper** bound on the type parameter.

If `A` is a supertype of `B`, then `GenericType<A>` is a supertype of `GenericType<? super B>`.
{: .notice}

### Contravariant containers

Contravariant containers behave counterintuitively: contrary to covariant containers, access to methods with return values of the type parameter are *inaccessible* while methods with input arguments of the type parameter *are* accessible:

You can exchange the subtype for the supertype:

{% highlight java %}
// Type hierarchy: Person > Joe > JoeJr
List<? super Joe> joes = new ArrayList<Joe>();  // ok
List<? super Joe> joes = new ArrayList<Person>(); // ok
List<? super Joe> joes = new ArrayList<JoeJr>(); // COMPILE ERROR
{% endhighlight %}

Cannot capture a specific type when reading from them:

{% highlight java %}
// Type hierarchy: Person > Joe > JoeJr
List<? super Joe> joes = new ArrayList<>();
Joe j = joes.get(0); // compile error (could be Object or Person)
Person p = joes.get(0); // compile error (ditto)
Object o = joes.get(0); // allowed because everything IS-A Object in Java
{% endhighlight %}

You *can* add subtypes of the "lower bound":

{% highlight java %}
// Type hierarchy: Person > Joe > JoeJr
List<? super Joe> joes = new ArrayList<>();
joes.add(new JoeJr()); // allowed
{% endhighlight %}

But you *cannot* add supertypes:

{% highlight java %}
// Type hierarchy: Person > Joe > JoeJr
List<? super Joe> joes = new ArrayList<>();
joes.add(new Person()); // compile error (again, could be a list of Object or Person or Joe)
joes.add(new Object()); // compile error (ditto)
{% endhighlight %}

## Bivariance in Java

The use-site must declare an **unbounded wildcard** on the type parameter.

A generic type with an unbounded wildcard is a supertype of all bounded variations of the same generic type. Eg. `GenericType<?>` is a supertype of `GenericType<String>`. Since the unbounded type is the root of the type hierarchy, it follows that of its parametric types it can only access methods inherited from `java.lang.Object`.

Think of `GenericType<?>` as `GenericType<Object>`.
{: .notice}

## Variance of structures with N type parameters

What about more complex types such as Functions? Same principles apply, you just have more type parameters to consider:

{% highlight java %}
// Type hierarchy: Person > Joe > JoeJr

// Invariance
Function<Person, Joe> personToJoe = null;
Function<Joe, JoeJr> joeToJoeJr = null;
personToJoe = joeToJoeJr; // COMPILE ERROR (personToJoe is invariant)

// Covariance
Function<? extends Person, ? extends Joe> personToJoe = null; // covariant
Function<Joe, JoeJr> joeToJoeJr = null;
personToJoe = joeToJoeJr;  // ok

// Contravariance
Function<? super Joe, ? super JoeJr> joeToJoeJr = null; // contravariant
Function<? super Person, ? super Joe> personToJoe = null;
joeToJoeJr = personToJoe; // ok
{% endhighlight %}

## Variance and Inheritance

Java allows overriding methods with covariant return types and exception types:

{% highlight java %}
interface Person {
  Person get();
  void fail() throws Exception;
}

interface Joe extends Person {
  JoeJr get();
  void fail() throws IOException;
}

class JoeImpl implements Joe {
  public JoeJr get() {} // overridden
  public void fail() throws IOException {} // overridden
}
{% endhighlight %}

But attempting to override methods with covariant *arguments* results in merely an overload:

{% highlight java %}
interface Person {
  void add(Person p);
}

interface Joe extends Person {
  void add(Joe j);
}

class JoeImpl implements Joe {
  public void add(Person p) {}  // overloaded
  public void add(Joe j) {} // overloaded
 }
{% endhighlight %}

## Final thoughts

Variance introduces additional complexity to Java. While the typing rules around variance are easy to understand, the rules regarding accessibility of methods of the type parameter are counterintuitive. Understanding them isn't just "obvious" - it requires pausing to think through the logical consequences.

However, my daily experience has been that the nuances generally stay out of the way:

* I cannot recall an instance where I had to declare a contravariant argument, and I rarely encounter them (although they *do* [exist](https://docs.oracle.com/javase/8/docs/api/java/util/Arrays.html#binarySearch-T:A-T-java.util.Comparator-)).
* Covariant arguments seem slightly more common ([example](https://github.com/yegor256/cactoos/blob/dc9c4b4f7c995fa7d328a130ea3e8611f589bb59/src/main/java/org/cactoos/text/Joined.java#L76)[^4]), but they're easier to reason about (fortunately).

Covariance is its strongest virtue considering that [subtyping](https://en.wikipedia.org/wiki/Subtyping) is a fundamental technique of object-oriented programming (case in point: see note [^4]).

**Conclusion:** variance provides moderate net benefits in my daily programming, particularly when compatibility with subtypes is required (which is a regular occurrence in OOP).

------

[^1]: [Taming the Wildcards: Combining Definition- and Use-Site Variance](https://yanniss.github.io/variance-pldi11.pdf) by John Altidor, et. al.

[^2]: As I understand it, the difference between use-site and definition-site variance is that the latter *requires* the variance be encoded into the generic type itself (think of having to declare `MyGenericType<? extends Number>`), forcing the API developer to preempt all use cases. C# defines variance at the definition-site. On the other hand, use-site variance doesn't have this restriction - the API developer can simply declare his API as generic and let the user determine variance for his use cases. The downside of use-site invariance are the "hidden" surprises described above, all derived from "conceptual complexity, [...] anticipation of generality at allusage points" (see *Taming the Wildcards* paper above).

[^3]: [Principle of least astonishment](https://en.wikipedia.org/wiki/Principle_of_least_astonishment) - Wikipedia. I vaguely remember a reference somewhere about the designers of Java following this principle but I can't seem to find it now.

[^4]: `Joined` concatenates several `Text`s. Declaring an invariant iterable of `Text` would make this constructor unusable to subtypes of `Text`.
