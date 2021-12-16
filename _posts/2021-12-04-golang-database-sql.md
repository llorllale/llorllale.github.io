---
layout: post
title: Golang - Deeper dive into database/sql
date: 2021-12-04
author: George Aristy
categories:
- programming
tags:
- go
- golang
- learning-go
- database
- sql
- java
- jdbc
---

*This post is part of a [series](https://llorllale.github.io/tags/learning-go) where I do my best to organize my
thoughts around Go: its paradigms and usability as a programming language. I write this as a Java programmer that
respects the principles of [Elegant Objects](https://www.elegantobjects.org/).*

This blog was motivated by a fellow programmer struggling with the DB connection lifecycle in Go whose modules were
fetching pooled connections but not releasing them after each use. They figured the best solution was to deliver
the connection pools (`*sql.DB`) to the different modules that required simple access to the databases
(`SELECT` queries). They wanted to take advantage of `sql.DB`'s automatic connection pooling features so that
they would never again incur the mistake of leaking connections. They also felt validated by the following statement
taken from the [godocs](https://pkg.go.dev/database/sql#Conn):

> Prefer running queries from DB unless there is a specific need for a continuous single database connection.

I was disappointed by the suggestion of handing out connection pools to multiple modules that required simple query
support. I was also once again troubled by the official sanction of a statement like the above quote without
nuance[^note1].

## Footnotes

[^note1]: Not the first time I've encountered statements like this in Go. 