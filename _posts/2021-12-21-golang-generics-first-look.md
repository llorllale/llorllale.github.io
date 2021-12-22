---
layout: post
title: Golang - First look at generics
date: 2021-12-21
author: George Aristy
categories:
- programming
- go
tags:
- go
- golang
- generics
- learning-go
- java
---

*This post is part of a [series](/tags/learning-go) where I do my best to organize my
thoughts around Go: its paradigms and usability as a programming language. I write this as a Java programmer that
respects the principles of [Elegant Objects](https://www.elegantobjects.org/).*

[Go 1.18 Beta 1 was just released](https://go.dev/blog/go1.18beta1). These are my initial impressions of the main
feature to be delivered in this release: generics.

## Syntax

Go's syntax possesses a very similar structure to Java's:

**Go**
```go
// A function.
func Print[T any](t T) {
    fmt.Printf("printing type: %T\n", t)
}

// A type.
type Tree[T any] struct {
    left, right *Tree[T]
    data  T
}
```

**Java**
```java
// A function.
public static <T> void print(T t) {
    System.out.println("printing type: " + t.getClass().getName());
}

// A type.
class Tree<T> {
    private Tree<T> left, right;
    private T data;
}
```

One difference: Go requires the type parameter to be explicitly constrained by a type (eg.: `T any`) whereas Java
does not (`T` on its own is implicitly inferred as a `java.lang.Object`). Failing to provide the constraint in Go will
result in an error similar to the following:

> ./prog.go:95:13: syntax error: missing type constraint

I suspect the difference lies in Java's unified type hierarchy (every thing is a `java.lang.Object`). Go possesses no such
model.

## Type Switch

The following compile error surprised me:

```go
func print[T any](t T) {
    switch t.(type) {
        case string: fmt.Println("printing a string: ", t) // error: cannot use type switch on type parameter value t (variable of type T constrained by any)
    }
}
```

... since the following is legal Go code:

```go
func print(t interface{}) {
    switch t.(type) {
        case string: fmt.Println("printing a string: ", t)
    }
}
```

This would appear to mean that `any` is not simply an alias for `interface{}` as declared by Robert Griesemer and Ian
Lance Taylor in [this talk](https://youtu.be/35eIxI_n5ZM?t=2477). This was raised in
[this issue](https://github.com/golang/go/issues/49206) that points to
[this rationale](https://go.googlesource.com/proposal/+/refs/heads/master/design/43651-type-parameters.md#why-not-permit-type-assertions-on-values-whose-type-is-a-type-parameter)
in an earlier draft of the proposal. This is especially surprising on union type parameters:

```go
func print[T int64|float64](t T) {
    switch t.(type) { // error: cannot use type switch on type parameter value t (variable of type T constrained by int64|float64)
        case int64:   fmt.Println("printing an int64: ", t)
        case float64: fmt.Println("printing a float64: ", t)
    }
}
```

While looking at the comments in this and related issues I get impression there's a decent chance that type-switching on
type parameters will be possible in the future. Just not in 1.18. To work around this, assign `t` to a variable of type
`interface{}` and type-switch on that.

In the meantime, here's the same feature in Java (combining [switch expressions](https://openjdk.java.net/jeps/361)
from Java 14 and [pattern matching for switch expressions (preview)](https://openjdk.java.net/jeps/406) in Java 17):

```java
public static <T> void print(T t) {
    switch(t) {
        case String s -> System.out.println("you sent string: " + s);
        default       -> System.out.println("you sent an unknown type: " + t.getClass().getName());
    };
}
```

## Type Constraints

In Go, the type parameter constraint `T any` indicates `T` is not constrained by any particular interface. In other words,
`T` implements `interface{}` (not quite; see [Type Switch](#type-switch)).

In Go we can further constrain the type set of `T` by indicating something other than `any`, eg.:

```go
// T is now constrained to int types.
type Tree[T int] struct {
    left, right *Tree[T]
    data  T
}
```

Equivalent Java:

```java
class Tree<T extends Integer> {
    private Tree<T> left, right;
    private T data;
}
```

In Go, type parameter declarations can specify concrete types (like Java) and can be declared inline or referenced:

```go
// inlined
func PrintInt64[T int64](t T) {
    fmt.Printf("%v\n", t)
}

// referenced
func PrintInt64[T Int64Type](t T) {
    fmt.Printf("%v\n", t)
}

// reusable (like constraints.Integer)
type Bit64Type interface {
    int64
}
```

### Go's reusable type constraints

Go's reusable type constraints are a bit... odd.

Take this simple example interface `Tester`:

```go
package main

type Tester interface {
    Test()
}

type myTester struct {}

func (m *myTester) Test() {}

func test(t Tester) {
    t.Test()
}

func main() {
    test(&myTester{})
}
```

... then add a type constraint:

```go
package main

type Tester interface {
    int64
    Test()
}

type myTester struct {}

func (m *myTester) Test() {}

func test(t Tester) { // ERROR: interface contains type constraints
    t.Test()
}

func main() {
    test(&myTester{})
}
```

Never mind that `int64` does not implement `Tester` - the error implies that arguments cannot be of interface types that
contain type constraints. This can be demonstrated even when both types implement the same methods:

```go
package main

type Tester interface {
    *myTester1
    Test()
}

type myTester1 struct {}

func (m *myTester1) Test() {}

type myTester2 struct {}

func (m *myTester2) Test() {}

func test(t Tester) { // ERROR: interface contains type constraints
    t.Test()
}

func main() {
    test(&myTester1{})
}
```

My surprise stems from the reuse of the `interface` construct when declaring type constraints. Adding type constraints
to an interface changes its nature entirely and limits its uses to generic type parameter declarations only. This will
come across as strange to veterans who are used to Go's structural typing system.

### Union Types

Both Go and Java support union types as type parameters but they do so in very different ways.

#### Union Types in Go

Go allows union types **for concrete types only**.

```go
// GOOD
func PrintInt64OrFloat64[T int64|float64](t T) {
    fmt.Printf("%v\n", t)
}

type someStruct {}

// GOOD
func PrintInt64OrSomeStruct[T int64|*someStruct](t T) {
    fmt.Printf("t: %v\n", t)
}

// BAD
func handle[T io.Closer | Flusher](t T) { // error: cannot use io.Closer in union (interface contains methods)
    err := t.Flush()
    if err != nil {
        fmt.Println("failed to flush: ", err.Error())
    }

    err = t.Close()
    if err != nil {
        fmt.Println("failed to close: ", err.Error())
    }
}

type Flusher interface {
    Flush() error
}
```

It seems like the primary motivation behind Go's union types (known as *type sets* in their proposal) is to enable generic
operations using operators such as `<` on primitive types that support them
(source: [proposal](https://go.googlesource.com/proposal/+/refs/heads/master/design/43651-type-parameters.md#operations-based-on-type-sets)).

Other examples of type sets are in the
[`constraints` package](https://github.com/golang/go/blob/2e6e9df2c1242274b02b584c617947aeed39c398/src/constraints/constraints.go#L48).

To my surprise, it is possible to declare a reusable type constraint that is impossible to satisfy:

```go
package main

type Tester interface {
    int    // int does not implement method `Test()`
    Test()
}

func test[T Tester](t T) {
    t.Test()
}

func main() {
    test(two(2)) // ERROR: two does not implement Tester (possibly missing ~ for int in constraint Tester)
}

type two int

func (t two) Test() {}
```

The error gives us a clue - use an
[approximation constraint element](https://go.googlesource.com/proposal/+/refs/heads/master/design/43651-type-parameters.md#approximation-constraint-element):

```go
package main

type Tester interface {
    ~int    // any type alias whose underlying type is an `int` will make do
    Test()
}

func test[T Tester](t T) {
    t.Test()
}

func main() {
    test(two(2)) // works
}

type two int

func (t two) Test() {}
```

Approximation constraint elements is about as close to covariance as Go will get in 1.18.

#### Union Types in Java

Java allows union types **for interface types only OR between a non-interface type and an interface type**.

```java
// GOOD
public static class Tree<T extends Closeable & Flushable> {
    private Tree<T> left, right;
    private T data;
}

// GOOD
public static <T extends Number & Closeable> void printNumberAndClose(T t) {
    System.out.println(t.intValue());

    try {
        t.close();
    } catch (IOException e) {
        System.out.println("io exception: " + e.getMessage());
    }
}

// BAD
public static <T extends Integer & Float> void printIntegerOrFloat(T t) { // error: interface expected here
    System.out.println(t.toString()); // error: ambiguous call
    System.out.println(t.isNaN());
}
```

As alluded to by the `&` ("and") operator, type parameters for union types in Java **must** satisfy all referenced "interfaces":

```java
public class Main {
  public static void main(String... args) {
      printNumberAndClose(new CloseableNumber());
      printNumberAndClose(12);                                  // ERROR: no instance(s) of type variable(s) exist so that Integer conforms to Closeable
      printNumberAndClose(new InputStreamReader(System.in));    // ERROR: no instance(s) of type variable(s) exist so that InputStreamReader conforms to Number
  }

  static class CloseableNumber extends Number implements Closeable {
      // implements methods from Closeable
      // implements abstract methods from Number
  }

  public static <T extends Number & Closeable> void printNumberAndClose(T t) {
      System.out.println(t.intValue());

      try {
          t.close();
      } catch (IOException e) {
          System.out.println("io exception: " + e.getMessage());
      }
  }
}
```

Similar to the Go example above, `printNumberAndClose` below will compile even though the conditions of the union type are
impossible to satisfy given that `java.lang.Integer` is a `final` class:

```java
public class Main {
  public static void main(String... args) {
      printNumberAndClose(new CloseableNumber(0));
      printNumberAndClose(12);                               // ERROR: no instance(s) of type variable(s) exist so that Integer conforms to Closeable
      printNumberAndClose(new InputStreamReader(System.in)); // ERROR: no instance(s) of type variable(s) exist so that InputStreamReader conforms to Integer
  }

  static class CloseableNumber extends Integer implements Closeable { // ERROR: Cannot inherit from final 'java.lang.Integer'
      CloseableNumber(int n) {
          super(n);
      }
      
      // implements methods from Closeable
  }

  public static <T extends Integer & Closeable> void printNumberAndClose(T t) {
      System.out.println(t.intValue());

      try {
          t.close();
      } catch (IOException e) {
          System.out.println("io exception: " + e.getMessage());
      }
  }
}
```

Worst that can happen is that nobody will use `printNumberAndClose`.

## Variance

Go's proposal
[does not include covariance nor contravariance](https://go.googlesource.com/proposal/+/refs/heads/master/design/43651-type-parameters.md#comparison-with-java).

Java supports both via the use of wildcards:

```java
// covariance
private static void sort(List<? extends Number> list) {
    // sort
}

// contravariance
private static void reverse(List<? super Number> list) {
    // reverse
}
```

I summarized Java's variance [in a previous blog post](/posts/java-variance)

## Final Thoughts

Although implementing a subset of Java's generics features and despite the hackiness of reusable typesets, Go's
proposal is compelling and worthy of trials in real production code once 1.18 rolls around.

Generics was a sorely missed feature in Go. I look forward to significant savings in lines of code as map/reduce algorithms
and data structures are de-duplicated altogether.
