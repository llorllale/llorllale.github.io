---
layout: post
title: OAuth2 Bearer Token Usage
excerpt: No matter what, as an implementer <strong>always</strong> verify your understanding of a specification against other implementations.
date: 2020-12-22
author: George Aristy
tags:
- oauth2
- authn
---

I have immersed myself in the digital identity space for the past few years. A good chunk of this work
involves reading (and sometimes creating) specifications, as you can imagine. It is critical that they
be written in such a way that two independent parties can build interoperable implementations
without relying on each other's code. With this in mind, let's have a brief chat about
[OAuth2 Bearer Token Usage](https://tools.ietf.org/html/rfc6750) with a focus on the token's encoding.

But first, let's have a briefly talk about what OAuth2 _is_. 

## What is OAuth 2.0?

OAuth2 is an authorization **_framework_** defined by [RFC6749](https://tools.ietf.org/html/rfc6749) outlining
the overall flow of messages between three actors: a "client", a resource owner (RO), and an authorization server (AS).
You might know the first two respectively as "relying party" and "user". Those of you familiar with
[OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html) also know the AS as the "Identity Provider".

At its heart, OAuth2 is all about a user authorizing a relying party to access their data hosted by an API
protected by the authorization server. Note that it does _not_ authorize _the user_ themselves to access the
API. The job of the AS is to collect and record the user's _consent_ to authorize the relying party access.

You might have noticed the emphasis on _framework_ above. That is because RFC6749 deliberately avoids
normative text defining many implementation details. Stepping back a bit, all RFC6749 says is that there is a client
that requests access to a resource protected by an authorization server, and that the resource owner must
approve this access. Once authorized, the client obtains an _access token_ to consume the resource.

OAuth2 relies on the [HTTP protocol](https://tools.ietf.org/html/rfc2616) and defines the basic structure of the messages
flowing between its actors. Relevant to the topic at hand is the [`token_type`](https://tools.ietf.org/html/rfc6749#section-7.1)
included in the response to the client. As per the RFC, this attribute "provides the client with the information
required to successfully utilize the access token to make a protected resource request".

## OAuth 2.0 Bearer Token Usage

[RFC6750](https://tools.ietf.org/html/rfc6750) is the normative specification for how to use OAuth 2.0 Bearer tokens.

What are "Bearer Tokens"?

Recall the `token_type` attribute from above. It turns out that if the access token response indicates the token's type
is `Bearer`, then it is a "bearer token" as defined in RFC6750, which means:

* [Any party in possession of the token can use it](https://tools.ietf.org/html/rfc6750#section-1.2), and
* It must be presented in a specific way (as defined in RFC6750).

This is, by far, the most common type of access token in use on the web today.

Great! I want to integrate social logins into my uber-mega website and disrupt a market overnight!
Let's get started!

## The misdirection

You have implemented one of the OAuth 2 grant types (aka "flows") as a client and the AS has issued a `Bearer`
access_token to you. What now? How do we use this token?

Luckily for us, RFC6750 tells us exactly what to do! Or does it? Let's explore my thought process on my first attempt at an implementation:

* The client must format an [`Authorization` HTTP header](https://tools.ietf.org/html/rfc6750#section-2.1)
with the token in a certain way.
* The syntax of bearer tokens includes a `b64token`: `b64token = 1*( ALPHA / DIGIT / "-" / "." / "_" / "~" / "+" / "/" ) *"="
* This strongly suggests that [Base64 encoding](https://tools.ietf.org/html/rfc4648#section-4) is involved in some way
* But, who encodes the access_token in Base64?
* Recall that the access_token is [usually opaque to the client](https://tools.ietf.org/html/rfc6749#section-1.4).
* Note that [HTTP headers can have almost any US-ASCII character](https://tools.ietf.org/html/rfc7230#section-3.2.6)
* Also recall that the access_token pretty much consists of [all printable characters](https://tools.ietf.org/html/rfc6749#appendix-A.12) - a superset of Base64
* If the access_token is opaque to the client (I shouldn't attempt to parse it), and it can also consist of invalid Base64 characters, then surely the client must Base64-encode the `Bearer` token, right?

But are we sure? Let's double check with RFC6750:

* The syntax of the "Authorization" header field for this scheme follows the usage of the Basic scheme defined in Section 2 of RFC2617
* Following through we find that RFC2617 defines the `Basic` HTTP Authentication Scheme that **also uses the `Authorization` HTTP header and Base64 to encode the credentials**

Putting it all together:

* RFC6750 defines how to use OAuth 2.0 Bearer Tokens
* Must put the access_token in the `Authorization` header
* The syntax includes a character space identified by `b64token`
* This usage follows the `Basic` scheme in RFC2617
* RFC2617 uses Base64 encoding

Great! All I have to do is encode the access_token in Base64 before putting it in the `Authorization` header.
I'm ready to integrate my social logins!

> **Narrator:** He was not ready for integration.

## The reality

Bearer tokens are laid bare in the `Authorization` header.
{: .notice}

None of the existing implementations expect the access_token to be encoded in Base64 in the `Authorization` header.
See for example:

* [Microsoft Identity Platform](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow#use-the-access-token)
* [GitHub's _Authorizing OAuth Apps_](https://docs.github.com/en/free-pro-team@latest/developers/apps/authorizing-oauth-apps#3-use-the-access-token-to-access-the-api)
* [An issue I filed with ORY Oathkeeper](https://github.com/ory/oathkeeper/issues/597) (only for me to subsequently realize my own confusion)

What gives? Did everyone else get it wrong? (because _of course_ **I** interpreted the spec correctly!)

## Lessons learned

It is **important** that specifications have precise normative text around how messages are constructed
and processed in order to be interoperable. If there are algorithms involved, **specify them step-by-step**.

It is **important** that normative text be labelled as such.

It is **important** to identify each role and their respective responsibilities and algorithms.

In my opinion, a good example showcasing the previous points is [Web Authentication](https://www.w3.org/TR/webauthn)
where:

* [The high-level architecture is clearly depicted in diagrams](https://www.w3.org/TR/webauthn/#sctn-api)
* Non-normative sections are clearly labelled.
* The interfaces are clearly defined
* Algorithms are explained in detail. Example: [Create a new credential](https://www.w3.org/TR/webauthn/#sctn-createCredential)

I'm still grappling with a real consolidation of RFC6750 with reality. If I squint just right
I can see that when RFC6750 says "The syntax for Bearer credentials is as follows" it was unnecessarily informing
the _client developer_ what the syntax of the token is. In hindsight, this seems to be a (rather terse) message
meant for implementers of Authorization Servers. I think an improved version of this section would have been
split into several parts, each directed at different audiences: one for developers of clients, another for developers
of authorization servers, and another for developers of resource servers. However, the text in RFC6750 remains
terse and mixes multiple implementation details that concern the different actors in a different manner.

Another improvement would be to rely less on _examples_ and to provide normative descriptions the (very simple) processing algorithms
that construct and parse these messages. That would have cleared up most of the confusion in the section 2.1,
although the language itself could have used stronger wording. Indeed, the non-normative text in section 7.1 of RFC6749
has stronger wording than that in RFC6750!

No matter what, as an implementer: **always** verify your understanding of a specification against other implementations!
{: .notice}
