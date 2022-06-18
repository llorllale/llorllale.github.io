---
layout: post
title: Kubernetes In Action
date: 2022-05-22 11:00:00 -0400
author: George Aristy
categories:
- books
- kubernetes
tags:
- kubernetes
- k8s
- devops
- cloud
- containers
- docker
- book
---

TODO this whole section

![cover](/assets/img/books/k8s-in-action/cover.jpg){: .left height="300" width="200" }
Written by [Marko Lukša](https://www.linkedin.com/in/marko-luk%C5%A1a-a71205/),
[Kubernetes In Action](https://www.manning.com/books/kubernetes-in-action) is a fantastic book covering all operational
aspects of Kubernetes. I find it _very_ hard to think of a better book on the subject. This is the first edition
of the book, published in December 2017, and although dated around the edges and details, Marko's in-depth dive into
the different components that make up Kubernetes and how they work is timeless. I highly recommend this book to anyone
looking for any serious learning of Kubernetes. This book's shelf life is pretty long considering Kubernetes' active
development - I would think it can only be supplanted by the
[second edition coming out later this year](https://www.manning.com/books/kubernetes-in-action-second-edition)[^1].

_Kubernetes In Action_ provided me with solid a theoretical and practical foundation on Kubernetes, enabling me to earn
the [Certified Kubernetes Application Developer](/posts/ckad) badge.

_Check out some other books I've read on the [bookshelf](/bookshelf/)._

# Summary

TODO

_Kubernetes In Action_'s roadmap takes us on a journey with the end goal of developing _Kubia_ - a contrived sample application - while exploring
the core concepts of Kubernetes in depth. Beyond the basics, the book explains the architecture, how pods
communicate with each other, how to secure your K8S cluster, pod affinity and anti-affinity, tolerations, the API service,
and how to extend Kubernetes with custom resources. The reader is kept engaged with practical exercises throughout by
applying configurations and testing them. These configurations and extra resources can be found in the book's
[GitHub repository](https://github.com/luksa/kubernetes-in-action).

It explains Kubernetes from two perspectives:

The configuration side:



# Chapters

## Introducing Kubernetes

Standard fare for books on Kubernetes; the chapter describes the breakdown of monoliths into microservices and the need
for a system like Kubernetes.

To my surprise it also explains what makes container isolation possible:
[linux namespaces](https://man7.org/linux/man-pages/man7/namespaces.7.html).

## First steps with Docker and Kubernetes

This chapter explains several of Docker's core concepts, such as how images are built, run, and pushed to the image registry.

Next we run our basic Docker image as a container in Kubernetes, but first we are given a choice as to our Kubernetes runtime
options: GKE or Minikube. This is where the book starts showing its age a little: the GCP machine type `f1-micro` is
[no longer suitable to run GKE on](https://serverfault.com/a/1015902/496858).

Next, we run the image on our K8S cluster using imperative commands. Here we observe some outdated technical details
as well: generators were [removed from `kubectl run`](https://github.com/kubernetes/kubernetes/pull/87077) quite a while ago[^2].

One of the things that makes this book great is that it doesn't just command the reader to run CLIs and be done with it; it
actually takes its time to explain what happens _behind the scenes_ as you run those commands.

We then expose the pod via a `LoadBalancer` service using `kubectl`. The instructions still work fine for GKE; however,
the book claims Minikube does not support this type of service. It does nowadays, but you need to run
[`minikube tunnel`](https://minikube.sigs.k8s.io/docs/commands/tunnel/) to expose them on your host.

## Pods: running containers in Kubernetes

## Replication and other controllers: deploying managed pods

## Services: enabling clients to discover and talk to pods

## Volumes: attaching disk storage to containers

## ConfigMaps and Secrets: configuring applications

## Accessing pod metadata and other resources from applications

## Deployments: updating applications declaratively

## StatefulSets: deploying replicated stateful applications

## Understanding Kubernetes internals

## Securing the Kubernetes API server

## Securing cluster nodes and the network

## Managing pods' computational resources

## Automatic scaling of pods and cluster nodes

## Advanced scheduling

## Best practices for developing apps

## Extending Kubernetes

# Footnotes

[^1]: It appears you can use code **au35luk** to get a <a target="_blank" href="https://github.com/luksa/kubernetes-in-action-2nd-edition#purchasing-the-book">35% discount <i class="fa fa-external-link-alt"></i></a>.
[^2]: Apparently, back then with generators, `kubectl run` would create a [`ReplicationController`](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/) to manage the pod's instances. While not outright deprecated, _ReplicationController_ are no longer recommended - use [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) instead.
