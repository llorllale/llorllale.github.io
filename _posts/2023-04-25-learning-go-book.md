---
layout: post
title: "Learning Go: An Idiomatic Approach to Real-World Go Programming"
date: 2023-04-25 08:00:00 -0400
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

_Learning Go_ exposes the early adopter to common sensible idioms used throughout the ecosystem.

## The comma-OK idiom

(page 54)

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

## Left-aligned, short `if` statement bodies

(page 70)

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
// not great
if v, ok := myMap["key"]; ok {
  // handle value
} else {
  // handle key not found
}

// better
v, ok := myMap["key"]
if !ok {
  // handle key not found
}

// handle value
```

The improvement in readability due to increased line-of-sight (see linked article) is worth the slight increase in
number of lines in my opinion.

## Types are executable documentation

(page 136)

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

## sync.Map Is Not The Map You Are Looking For

(page 240)

I generally find Go's community and (in some cases) its documentation rather dogmatic and prescriptive when compared
to others. The practical effect of this in the real world is it tends to lead the novice/mid-level engineer to the
incorrect conclusion that a certain API or pattern is the best fit for their use case. [sync.Map](https://pkg.go.dev/sync#Map)
is one of those cases where the documentation generally leads engineers to suboptimal solutions in terms of performance[^1]:

> Map is like a Go map[interface{}]interface{} but is safe for concurrent use by multiple goroutines without additional
> locking or coordination. Loads, stores, and deletes run in amortized constant time.
> 
> The Map type is specialized. Most code should use a plain Go map instead, with separate locking or coordination, for
> better type safety and to make it easier to maintain other invariants along with the map content.
> 
> The Map type is optimized for two common use cases: (1) when the entry for a given key is only ever written once but
> read many times, as in caches that only grow, or (2) when multiple goroutines read, write, and overwrite entries for
> disjoint sets of keys. In these two cases, use of a Map may significantly reduce lock contention compared to a Go
> map paired with a separate Mutex or RWMutex.

The first paragraph informs us that this map is safe for concurrent reads and writes. This map has had type parameters
ever since generics were introduced in Go 1.18, so this line is outdated.

The second paragraph recommends use of the plain map with more common synchronization primitives (locks, channels).
One of the reasons for this recommendation - better type safety - is now outdated. It's a rather short paragraph.

The third paragraph is longer and is the one most likely to mislead the novice/mid-level engineer: as an authoritative
source, it gives the impression that if your use case matches the two enumerated there then you should use `sync.Map`
without further consideration. The second paragraph's recommendation is usually brushed away after reading this one.

A good engineer should have further considerations before deciding on whether to use `sync.Map`:

* Are [stampedes](https://en.wikipedia.org/wiki/Cache_stampede) a concern?
* Are external services impacted when populating the cache?
* How large is the cache expected to grow?
* How frequently are cache entries added?
* Are cache entries ever updated after being added?
* How expensive is it to create entries for the cache and how does it stack against the
  [40ns it takes to transfer L2 caches between CPUs](https://youtu.be/C1EtfDnsdDs?t=67) as per the original author of
  `sync.Map`? How many cores do your nodes have?

And I'm sure there are more.

In my experience, caches are usually held in memory somewhere and implemented because the cached data is "expensive"
to create. Given this, scenario (1) is always served more optimally with judicious use of `sync.RWMutex` and a plain map
to protect against stampedes (a frequent concern), or with a plain map and `atomic.Pointer` to implement a
[read-copy-update](https://en.wikipedia.org/wiki/Read-copy-update) scheme if the cache is updated infrequently.

I have yet to come across scenario (2), but some of those questions would still apply.

In conclusion, I think `sync.Map` is overused and I also think Go's API documentation should limit its prescriptive
language and just state the facts of how its APIs operate.

## Avoid APIs that depend on exposed package-level state

(page 251)

"Avoid APIs that depend on exposed package-level state" is my key takeaway from the book:

> There are package-level functions, http.Handle, http.HandleFunc, [...] Don't use them outisde of trivial test
> programs. [...] Furthermore, third-party libraries could have registered their own handlers with the `http.DefaultServeMux`
> and there's no way to know without scanning through all of your dependencies (both direct and indirect). Keep your
> application under control by avoiding shared state.

The following example illustrates the point.

Your code:

```go
import (
	"net/http"

	"scratchpad/global/helper"
)

func main() {
	http.Handle("/myAPI", http.HandlerFunc(myHandler))
}

func myHandler(w http.ResponseWriter, r *http.Request) {
	// read request

	// do awesome stuff

	result := "success " + helper.DoSomethingHelpful()

	_, _ = w.Write([]byte(result))
}
```

What your "awesome" helper is doing:

```go
package helper

import "net/http"

func init() {
	http.DefaultServeMux.Handle("/secrets", http.HandlerFunc(exposeSecrets))
}

func DoSomethingHelpful() string {
	return "great work done here"
}

func exposeSecrets(w http.ResponseWriter, r *http.Request) {
	// expose all your secrets from env vars, local filesystem, etc.
}
```

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

## Alias declarations

(page 189)

I was aware of aliases but never bothered to look closely at them since I haven't had the need to declare them myself,
although I have used some from the standard library plenty of times. Some of these may surprise you:

* `byte`, `rune`, and `any` are aliases (see [code](https://github.com/golang/go/blob/4fe46cee4ea4eb15e38675ff32222f07e6b15404/src/builtin/builtin.go#L85-L95))
* [`os.PathError`](https://github.com/golang/go/blob/979956a7321e74f1441ae2a05c9dc6560d7fe84c/src/os/error.go#L46),
  [`os.FileInfo`, `os.FileMode`](https://github.com/golang/go/blob/d4da735091986868015369e01c63794af9cc9b84/src/os/types.go#L20-L28),
  and [`os.DirEntry`](https://github.com/golang/go/blob/3d913a926675d8d6fcdc3cfaefd3136dfeba06e1/src/os/dir.go#L82) are also aliases

The difference between [alias declarations](https://go.dev/ref/spec#Alias_declarations) and [type definitions](https://go.dev/ref/spec#Type_definitions)
is the former does not create a new type; it merely creates a new name that can also be used to refer to the type definition.

The following example defines type `Person` and an alias to it, `Alice`. Outwardly the code seems to define a new method
on `Alice`, but really the method is attached to `Person` and also invokable from a reference to `Alice`:

```go
type Person struct {
	name string
}

func (p *Person) Name() string {
	return p.name
}

type Alice = Person

func (a *Alice) Greet() string {
	return fmt.Sprintf("Hello, my name is %s!", a.name)
}

func main() {
	a := &Alice{name: "Alice"}
	fmt.Println(a.Name())

	p := &Person{name: "Alice"}
	fmt.Println(p.Name())
	fmt.Println(p.Greet())
}
```

Before you get any ideas though - there is no way to get around the hard restriction on modifying the structure of types
in different packages:

```go
import "os"

type ErrSneaky = os.PathError

func (e ErrSneaky) DoEvil() { // error: Cannot define new methods on the non-local type 'fs.PathError'
  // do something evil
}
```

## Writing to channels in select statements

(page 211)

Not 100% surprising but then again - I have never come across a use case for this:

Cases in a [select statement](https://go.dev/ref/spec#Select_statements) can include "send statements"
(ie. writing to a channel) as well as receiving operations (ie. reading from a channel); a single instance of `select`
can have both.

## Monotonic time

(page 240)

When available, Go internally uses [monotonic clocks](https://pkg.go.dev/time#hdr-Monotonic_Clocks) to calculate
[durations](https://pkg.go.dev/time#Duration) between two points in [Time](https://pkg.go.dev/time#Time).

This is a fascinated topic that really deserves an article of its own, so I won't discuss it here. Dropping a couple
of links for those interested:

* [GoDoc](https://pkg.go.dev/time#hdr-Monotonic_Clocks)
* [Long discussion on GitHub](https://github.com/golang/go/issues/12914)
* [How and why the leap second affected Cloudflare DNS](https://blog.cloudflare.com/how-and-why-the-leap-second-affected-cloudflare-dns/)

## JSON Decoder

(page 245)

I have been using [json.Decoder](https://pkg.go.dev/encoding/json#Decoder) in my APIs since forever because of the way it collapses two
actions into one.

Compare this:

```go
func myHandler(w http.ResponseWriter, r *http.Request) {
  payload, err := io.ReadAll(r.Body)
  if err != nil {
    // handle error
  }
  
  request := &MyRequest{}
  
  err = json.Unmarshal(payload, request)
  if err != nil {
    // handle error
  }
  
  // process request
}
```

to this:

```go
func myHandler(w http.ResponseWriter, r *http.Request) {
  request := &MyRequest{}
  
  err := json.NewDecoder(r.Body).Decode(request)
  if err != nil {
    // handle error
  }
  
  // process request
}
```

The benefits and features of `json.Decoder` do not stop there though:

**It can decode multiple values**

```go
type Person struct {
	Name string `json:"name"`
	Age  int    `json:"age"`
}

type USD struct {
	Dollars int `json:"dollars"`
	Cents   int `json:"cents"`
}

func main() {
	r := strings.NewReader(`
		{"name": "Alice", "age": 32}
		{"dollars": 10, "cents": 2}
	`)

	decoder := json.NewDecoder(r)

	person := Person{}
	usd := USD{}

	err := decoder.Decode(&person)
	if err != nil {
		panic(err)
	}

	err = decoder.Decode(&usd)
	if err != nil {
		panic(err)
	}

	fmt.Printf("%v\n", person)
	fmt.Printf("%v\n", usd)
}
```

Note that this feature is typically used to decode sequences of objects of the same type in a loop using
[Decoder.More()](https://pkg.go.dev/encoding/json#Decoder.More) as exit condition.

**It can be more performant**

Followup from above, `json.Decoder` only
[reads the next object or array from the stream](https://github.com/golang/go/blob/21ff6704bc8efa72abe191263aae938f3c867480/src/encoding/json/stream.go#L87-L144)
and no more[^2].

# Things I am on the fence about

## Accept Interfaces, Return Structs

(page 146)

["Accept Interfaces, Return Structs"](https://medium.com/@cep21/preemptive-interface-anti-pattern-in-go-54c18ac0668a) is a
structural pattern first popularized by [Jack Lindamood](https://medium.com/@cep21) way back in 2016, so it's been around a
while.

I think this pattern is at its strongest when working in big, fast-paced teams with engineers who may yet have not developed
their design skills to its full potential. However, it's just altogether _easier_ to keep diluting a type's "purpose" by tacking
on more and more methods to its API. Not many people are capable of thinking in higher-level, more abstract terms like
["Input", "Output", "Scalar", "Func", etc.](https://www.javadoc.io/doc/org.cactoos/cactoos/latest/org/cactoos/package-summary.html).
So when you stop to think about it, "accept interfaces, return structs" is at its strongest when another universal best practice
is thrown by the wayside: 
["the bigger the interface, the weaker the abstraction"](https://www.javadoc.io/doc/org.cactoos/cactoos/latest/org/cactoos/package-summary.html).
And from where I am standing, a "best practice" that only stands strong by weakening another best practice doesn't net you
much at all from a philosophical standpoint.

After years of programming in Go, I still actually _do_ recommend this pattern to other team members, but I admit I am not fully
convinced.

- TODO things I learned:
  - Invoking a function with args of type interface will result in a heap allocation for each of the interface types (p147)
  - "empty struct uses no memory" (p263)
  - benchmarks! (p283)
  - use reflect to make functions and structs (p312-313)
  - performance boost when using unsafe.Pointer (p317-319)

- TODO Outdated?
  - converting arrays to slices (p46)

- errata
  - "goroutines are lightweight processes" (p205). refer to my own talk on the subject

---

[^1]: The other one I can think of is [database/sql](https://pkg.go.dev/database/sql) where the docs for [Conn](https://pkg.go.dev/database/sql#Conn) say "Prefer running queries from DB unless there is a specific need for a continuous single database connection". This leads some engineers to write service logic that _receives_ a [*sql.DB](https://pkg.go.dev/database/sql#DB) including its administrative methods (`SetConnMaxIdleTime`, `SetConnMaxLifetime`, etc).
[^2]: May read a little more than required because the minimum bytes to be read is 512: https://github.com/golang/go/blob/21ff6704bc8efa72abe191263aae938f3c867480/src/encoding/json/stream.go#L146-L169