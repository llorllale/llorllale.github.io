---
layout: post
title: "Learning Go: An Idiomatic Approach to Real-World Go Programming"
date: 2023-04-04 15:00:00 -0400
author: George Aristy
categories:
- books
- golang
tags:
- book
- go
- golang
---

![book cover](/assets/img/books/learning-go/front-cover.jpg){: .left height="300" width="200" }
Written by [Jon Bodner](https://www.linkedin.com/in/jonbodner/), 
[Learning Go: An Idiomatic Approach to Real-World Go Programming](https://www.amazon.ca/Learning-Go-Idiomatic-Real-World-Programming/dp/1492077216)
is, in my opinion, one of the best resources there is to learn [Go](https://go.dev/), particularly if you are somewhere
around the intermediate stage with a couple of years under your belt. From the basic topics covered at the start all
the way to `cgo`, reflection, and `unsafe`, this book covers it all, complete with tips on writing idiomatic code.
I can guarantee this book will leave you with strongly reinforced learnings and new knowledge.

The book came out right before [Go 1.18 was released](https://tip.golang.org/doc/go1.18) (mayor feature being generics),
but everything contained in this book still holds beautifully.

I highly recommend this book for those that value Go as a professional tool and are serious about mastering it.

_Check out some other books I've read on the [bookshelf](/bookshelf/)._

# Summary

_Learning Go_ is a complete treasure trove of learnings about everything related to Go: its syntax, standard tools,
standard APIs, common idioms, common sources of bugs, great insight into the reasons for the design of some of
Go's APIs and operators, and ending with advanced topics such as `cgo` and `unsafe`. No prior knowledge of Go is required
from the reader; given prior exposure to other similar programming languages, this book will effortlessly take the
reader from zero to hero.

# Some of the things I liked

_Learning Go_ exposes the early adopter to common sensible idioms used throughout the ecosystem:

<details>
  <summary markdown="span">comma-OK idiom (page 54)</summary>

  <div markdown="1">

  Simple way to differentiate between a type's [zero value](https://go.dev/ref/spec#The_zero_value) and its absence, usually
  as return values from some sort of API (typically a [map](https://go.dev/ref/spec#Map_types)).

  ```go
  v, ok := myMap["key"]
  if !ok {
    // handle key not found
  }
  
  // handle value
  ```

  Note that if your API may return an [error](https://go.dev/ref/spec#Errors) for other reasons, then it's better to
  use a sentinel error:

  ```go
  var ErrNotFound = errors.New("my sentinel error")
  
  v, err := myAPI.Get("key")
  if errors.Is(ErrNotFound) {
    // handle key not found
  }
  
  if err != nil {
    // handle other error
  }
  
  // handle value
  ```

  Lastly, the comma-OK idiom is implemented by [channels](https://go.dev/ref/spec#Channel_types) (to differentiate
  between the zero-value and a closed channel) and [type assertions](https://go.dev/ref/spec#Type_assertions) (to
  know whether the assertion is true).

  </div>
</details>

<details>
  <summary markdown="span">left-aligned, short `if` statement bodies (page 70)</summary>

  <div markdown="1">

  Avoid deeply nested structures:

  ```go
  // BAD
  if i%3 == 0 {
    if i%5 == 0 {
      return "FizzBuzz"
    } else {
      return "Fizz"
    }
  } else if i%5 == 0 {
    return "Buzz"
  } else {
    return fmt.Sprint(i)
  }
  
  // GOOD
  if i%3 ==0 && i%5 == 0 {
    return "FizzBuzz"
  }
  
  if i%3 == 0 {
    return "Fizz"
  }
  
  if i%5 == 0 {
    return "Buzz"
  }
  
  return fmt.Sprint(i)
  ```

  In addition, I endorse ["The Happy path is left-aligned"](https://medium.com/@matryer/line-of-sight-in-code-186dd7cdea88)
  even when using the comma-OK idiom:

  ```go
  // BAD
  if v, ok := myMap["key"]; ok {
    // handle value
  } else {
    // handle key not found
  }
  
  // GOOD
  v, ok := myMap["key"]
  if !ok {
    // handle key not found
  }
  
  // handle value
  ```

  The improvement in readability due to increased line-of-sight (see linked article) is worth the slight increase in
  number of lines in my opinion.

  </div>
</details>

<details>
  <summary markdown="span">types are executable documentation (page 136)</summary>

  <div markdown="1">

  [User-defined types](https://go.dev/ref/spec#Type_declarations) add clarity by exposing the concept represented by a given value. Imagine
  [functional options](https://dave.cheney.net/2014/10/17/functional-options-for-friendly-apis) without a custom type:

  ```go
  func DoSomething(ctx context.Context, key string, opts ...func(*Config)) error {
    // do something
  }
  ```

  This API's clarity can be enhanced as follows:

  ```go
  type Option func(*Config)
  
  func DoSomething(ctx context.Context, key string, opts ...Option) error {
    // do something
  }
  ```

  But user-defined types can do much more than this. Consider [http.HandlerFunc](https://pkg.go.dev/net/http#HandlerFunc):

  ```go
  type HandlerFunc func(ResponseWriter, *Request)
  
  func (f HandlerFunc) ServeHTTP(w ResponseWriter, r *Request) {
    f(w, r)
  }
  ```

  In this case, the type serves as an _adapter_ for user-provided functions that meet the signature requirements. This
  frees the user from having to define a whole `struct` type just to implement the one `ServeHTTP` method:

  ```go
  func main() {
	mux := http.NewServeMux()
	mux.Handle("/foo", http.HandlerFunc(handleFoo)) // just cast the function to http.HandlerFunc

	err := http.ListenAndServe(":8080", mux)
	if err != nil {
	  log.Fatal(err)
	}
  }

  func handleFoo(w http.ResponseWriter, r *http.Request) {
	// handle foo
  }
  ```

  One other advantage of user-defined types is that they have the potential to stop being simple data structures or primitives
  and start having useful behaviour. Consider the following example:
  
  ```go
  func main() {
	percentage := 0.2
	subtotal := 29.5

	ApplyDiscount(subtotal, percentage)

	fmt.Printf("applied %.0f%%\n", percentage*100)
  }

  func ApplyDiscount(subtotal, percentage float64) {
	// do something
  }
  ```

  Let's make "percentage" more useful as a first-class concept:

  ```go
  type Percentage int

  func (p Percentage) String() string {
	return fmt.Sprintf("%d%%", p)
  }

  func (p Percentage) Float() float64 {
	return float64(p / 100)
  }

  func main() {
	var percentage Percentage = 20
	subtotal := 29.5

	ApplyDiscount(subtotal, percentage)

	fmt.Printf("applied %s\n", percentage)
  }

  func ApplyDiscount(subtotal float64, p Percentage) {
	// do something
  }
  ```

  Another example - an in-memory datastore useful for tests:

  ```go
  type Store[K comparable, V any] interface {
	Get(k K) (V, error)
	Put(k K, v V) error
  }

  type mockStore[K comparable, V any] map[K]V

  func (m mockStore[K, V]) Get(k K) (V, error) {
	return m[k], nil
  }

  func (m mockStore[K, V]) Put(k K, v V) error {
	m[k] = v
	return nil
  }
  ```

  </div>
</details>

# Some of the things I learned

A selection of some of the most interesting or surprising things I learned about Go.

## Complex numbers

Learned this one right out the gate at page 24.

Go supports [complex numbers](https://go.dev/ref/spec#Complex_numbers). You can perform arithmetic operations on them,
and they are comparable (eg. can be used as keys in a map). The following example prints `(4+6i)` and `a`:

```go
func main() {
	a := complex(1, 2)
	b := complex(3, 4)
	c := a + b
	fmt.Println(c)

	m := map[complex128]string{
		a: "a",
		b: "b",
	}

	fmt.Println(m[a])
}
```

## Struct conversion

(page 59)

Anonymous structs are interchangeable if their fields align perfectly and are comparable:

```go
func main() {
	alice := struct {
		Name string
		Age  int
	}{
		Name: "Alice",
		Age:  30,
	}
	garfield := struct {
		Name string
		Age  int
	}{
		Name: "Garfield",
		Age:  2,
	}
	garfield = alice
	fmt.Printf("%+v\n", garfield)
}

// Output:
//   {Name:Alice Age:30}
```

This is particularly useful when populating third-party structs with fields that are anonymous structs.
Instead of having to do this:

```go
type Config struct {
	Simple1    string
	Simple2    string
	Composite1 struct {
		Name  string
		Date  time.Time
		Value int
	}
	Composite2 struct {
		Name  string
		Date  time.Time
		Value int
	}
}

func main() {
	conf := Config{
		Simple1: "one",
		Simple2: "two",
		Composite1: struct {
			Name  string
			Date  time.Time
			Value int
		}{
			Name:  "alice",
			Date:  time.Now(),
			Value: 1,
		},
		Composite2: struct {
			Name  string
			Date  time.Time
			Value int
		}{
			Name:  "bob",
			Date:  time.Now(),
			Value: 4,
		},
	}

	fmt.Printf("%+v\n", conf)
}
```

You can save a few lines by declaring an anonymous struct that matches the structure of the composite fields:

```go
type Config struct {
	Simple1    string
	Simple2    string
	Composite1 struct {
		Name  string
		Date  time.Time
		Value int
	}
	Composite2 struct {
		Name  string
		Date  time.Time
		Value int
	}
}

func main() {
	type composite struct {
		Name  string
		Date  time.Time
		Value int
	}

	conf := Config{
		Simple1: "one",
		Simple2: "two",
		Composite1: composite{
			Name:  "alice",
			Date:  time.Now(),
			Value: 1,
		},
		Composite2: composite{
			Name:  "bob",
			Date:  time.Now(),
			Value: 4,
		},
	}

	fmt.Printf("%+v\n", conf)
}
```

## The Universe Block

(page 65)

I was surprised to learn that what I thought were special keywords that could not be used anywhere in code are actually
[predeclared identifiers](https://go.dev/ref/spec#Predeclared_identifiers) in the _universe block_: the block in which
all code is in scope. Because they are mere (predeclared) _identifiers_ and not keywords, they can be shadowed just like
any other identifier:

```go
func main() {
	nil := 1
	fmt.Println(nil)
	append := "append"
	fmt.Println(append)
}

// Output:
//  1
//  append
```

## Reducing the garbage collector's workload

(page 123)

TODO

## Pointer Receivers vs Value Receivers

(page 132)

> Go considers both pointer and value receiver methods to be in the method set for a pointer instance. For a value instance, 
> only the value receiver methods are in the method set.

The practical effect of this is that one cannot assign a value type to a variable of an interface type if the former
does not have methods with value-type receivers that implement the interface:

```go
type Greeter interface {
	Greet()
}

type Runner interface {
	Run()
}

type Athlete struct{}

func (a *Athlete) Greet() {
	fmt.Println("Hello there!")
}

func (a Athlete) Run() {
	fmt.Println("I am running!")
}

func main() {
	var a Greeter = &Athlete{}
	var b Greeter = Athlete{} // compile error!
	var c Runner = &Athlete{}
	var d Runner = Athlete{}
}
```

I had never given much though to this distinction and now got curious - _why?_ The Golang FAQ has an
[answer](https://go.dev/doc/faq#different_method_sets):

> This distinction arises because if an interface value contains a pointer *T, a method call can obtain a value by
> dereferencing the pointer, but if an interface value contains a value T, there is no safe way for a method call to
> obtain a pointer. (Doing so would allow a method to modify the contents of the value inside the interface, which is
> not permitted by the language specification.)
> 
> Even in cases where the compiler could take the address of a value to pass to the method, if the method modifies the
> value the changes will be lost in the caller. As an example, if the Write method of bytes.Buffer used a value receiver
> rather than a pointer, this code:
> ```go
> var buf bytes.Buffer
> io.Copy(buf, os.Stdin)
> ```
> would copy standard input into a copy of buf, not into buf itself. This is almost never the desired behavior.

The second reason is fairly easy to understand: if [bytes.Buffer](https://pkg.go.dev/bytes#Buffer) had a value receiver
for its [Write](https://pkg.go.dev/bytes#Buffer.Write) method, then `io.Copy` would write
the contents of `os.Stdin` to a _copy_ of `buf`, not the caller's copy.

The first reason is a bit more esoteric: if value types were allowed to implement interfaces then any method call that
modifies the value itself would also modify the interface object itself. Or should they modify a copy made on the fly?
What would be the ramifications of that? Does the caller's reference to the interface object magically update to the new value?
Or should the changes be effected on a different copy than the caller's? Rather than opening up this can of worms, the Go
team decided to simplify the mental model by this rule prohibiting this edge case.

- idioms
  - grrr "accept interfaces, return structs" (p146)

- TODO things I learned:
  - iota (p137)
  - Invoking a function with args of type interface will result in a heap allocation for each of the interface types (p147)
  - interfaces and nil (p147)
  - function types as a bridge to interfaces (p154)
  - aliases versus types? (p189)
  - How channels behave (p209)
  - writing to channels in a `select` `case` (p211)
  - buffered, unbuffered channels, and backpressure (p217-218)
  - how to time out code (p219). refer to time.After vs Context.Done()
  - sync.Map - this is not the map you are looking for (p230)
  - reason why Go implements monotonic time (p240)
  - json.NewDecoder can decode multiple values (p245). Also I think it only reads just enough bytes (maybe slightly more) to decode a single type
  - we shouldn't use the static functions of `http` package because other packages may have registered their own handlers
    in the default serve mux. "keep your application under control by avoiding shared state" (p251)
  - http.StripPrefix (p251)
  - limit number of queued requests with buffered channels and a `select` (p262)
  - "empty struct uses no memory" (p263)
  - benchmarks! (p283)
  - "short tests" (p295)
  - use reflect to make functions and structs (p312-313)
  - performance boost when using unsafe.Pointer (p317-319)

- TODO Outdated?
  - converting arrays to slices (p46)

- errata
  - "goroutines are lightweight processes" (p205). refer to my own talk on the subject