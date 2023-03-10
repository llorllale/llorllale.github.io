---
layout: post
title: "Kubernetes' Controller Manager"
date: 2023-03-10 08:50:00 -0500
author: George Aristy
tags:
- kubernetes
- k8s
- kube-controller-manager
---

![cover](/assets/img/Kubernetes-icon-color.svg){: .left width="100" }
[Kubernetes](https://kubernetes.io/) is a platform that automates many of the complexities behind deployment, scaling,
and management of resources, such as [pods](https://kubernetes.io/docs/concepts/workloads/pods/). Users can configure
these resources imperatively using [kubectl](https://kubernetes.io/docs/reference/kubectl/), or declaratively using
configuration files (also deployed using kubectl). At the heart of this platform lies a control loop that works to
bring the _current state_ of those resources to the _desired state_.

![control loop](/assets/img/k8s-controller-manager/control%20loop.drawio.svg)

In this article we will take a brief look at the component that manages this control loop:
[kube-controller-manager](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/).

# Architecture

The controller manager is part of Kubernetes’
[control plane](https://kubernetes.io/docs/concepts/overview/components/#control-plane-components) and runs on the
master nodes, normally as a standalone pod. It _manages_ many built-in controllers for different resources such as
deployments or namespaces. You can find the full list of managed controllers
[here](https://github.com/kubernetes/kubernetes/blob/95051a63b323081daf8a3fe55a252eb79f0053aa/cmd/kube-controller-manager/app/controllermanager.go#L434-L480).

The controller manager registers
“[watches](https://kubernetes.io/docs/reference/using-api/api-concepts/#efficient-detection-of-changes)” on the
[API server](https://kubernetes.io/docs/concepts/overview/components/#kube-apiserver) that open a connection through
which events are constantly streamed. Each of these events has an associated _action_, such as “add” or “delete”,
and a target resource. The controller manager then dispatches these events to controllers that have registered
themselves to act on them based on the event’s action and the type of the target resource. Note that these controllers
do _not_ realize the end result directly (ie. create containers, create IP addresses, etc.), they merely update
resources that are exposed on the API server itself. In other words, they update the _desired state_ of those resources.
Other components, such as the [kubelet](https://kubernetes.io/docs/concepts/overview/components/#kubelet) or
[kube-proxy](https://kubernetes.io/docs/concepts/overview/components/#kube-proxy), perform the actual grunt work
derived from the desired state. Such is the distributed nature of the Kubernetes as a system.

![controller events](/assets/img/k8s-controller-manager/kube-controller-manager-events.drawio.png)
_High level view of a small subset of what happens when a new deployment is added._

# In the cloud

In cloud environments, the [cloud-controller-manager](https://kubernetes.io/docs/concepts/architecture/cloud-controller/)
runs alongside the kube-controller-manager. This controller manager operates the same way as the built-in
`kube-controller-manager` in principle, with its control loops tailored specifically for management of cloud
infrastructure. It is this controller manager that handles updates from the cloud provider: nodes automatically entering
or leaving the cluster, provisioning of load balancers, updating IP routes within your cluster, and so on. In the
diagram below, the `cloud-controller-manager` is the “CCM” box while the regular `kube-controller-manager` is represented
by the “CM” box.

![components](/assets/img/k8s-controller-manager/components-of-kubernetes.svg)
_Image taken from [Kubernetes docs](https://kubernetes.io/docs/concepts/architecture/cloud-controller/#design)._

# Conclusion

Kubernetes is a distributed system that serves as a platform that automates many of the complexities behind deployment,
scaling, and management of applications. The `kube-controller-manager` implements many critical control loops that
ensure the cluster’s current state matches the user’s desired state. These control loops function independently of each
other, listening for events from the API server and modifying resources there as well. Other components, such as the
`kube-proxy` and the `kubelet` perform the actual runtime configurations on the cluster’s nodes. In cloud environments,
the `cloud-controller-manager` runs alongside the `kube-controller-manager` and implements control loops specific to
cloud infrastructure.






- TODO fix text labels in SVGs
- TODO expand on control plane vs data plane
- TODO expand on what Watches are a little bit
- TODO maybe expand on distributed systems architectures