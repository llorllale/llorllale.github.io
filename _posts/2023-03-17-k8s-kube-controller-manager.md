---
layout: post
title: "Kubernetes' Controller Manager"
date: 2023-03-17 07:10:00 -0400
author: George Aristy
categories:
  - cloud-computing
  - k8s
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

In this article we will take a brief look at the component that manages the main control loop,
[kube-controller-manager](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/),
as well as the [cloud-controller-manager](https://kubernetes.io/docs/concepts/architecture/cloud-controller/) that manages
the control loops specific to cloud environments.

# Architecture

![components](/assets/img/k8s-controller-manager/components-of-kubernetes.svg)
_Image taken from [Kubernetes docs](https://kubernetes.io/docs/concepts/architecture/cloud-controller/#design).<br/>
"CM" represents `kube-controller-manager` and "CCM" represents `cloud-controller-manager`._

The controller manager is part of Kubernetes’
[control plane](https://kubernetes.io/docs/concepts/overview/components/#control-plane-components)[^1] and runs on the
master nodes, normally as a standalone pod. It _manages_ many built-in controllers for different resources such as
deployments or namespaces. You can find the full list of managed controllers
[here](https://github.com/kubernetes/kubernetes/blob/95051a63b323081daf8a3fe55a252eb79f0053aa/cmd/kube-controller-manager/app/controllermanager.go#L434-L480).

Kubernetes implements an event-driven architecture with many independent components reacting to events and acting in
concert to drive the system to a desired state. 
The controller manager registers
“[watches](https://kubernetes.io/docs/reference/using-api/api-concepts/#efficient-detection-of-changes)” on the
[API server](https://kubernetes.io/docs/concepts/overview/components/#kube-apiserver) that open a connection through
which events are constantly streamed[^2]. Each of these events has an associated _action_, such as “add” or “delete”,
and a target resource. Here's an example from the docs:

```
GET /api/v1/namespaces/test/pods?watch=1&resourceVersion=10245
---
200 OK
Transfer-Encoding: chunked
Content-Type: application/json

{
  "type": "ADDED",
  "object": {"kind": "Pod", "apiVersion": "v1", "metadata": {"resourceVersion": "10596", ...}, ...}
}
{
  "type": "MODIFIED",
  "object": {"kind": "Pod", "apiVersion": "v1", "metadata": {"resourceVersion": "11020", ...}, ...}
}
...
```

The event actions are determined by their `type`, and the target resource is the `object`. Note how `object` is just
a regular spec (Pod specs in this example).

The controller manager dispatches these events to controllers that have registered
themselves to act on them based on the event’s action and the type of the resource. Note that these controllers
do _not_ realize the end result directly (ie. create containers, create IP addresses, etc.), they merely update
resources that are exposed on the API server itself. In other words, they update the _desired state_ of those resources
by posting the updated spec back to the API server.
It is other components, such as the [kubelet](https://kubernetes.io/docs/concepts/overview/components/#kubelet) and the
[kube-proxy](https://kubernetes.io/docs/concepts/overview/components/#kube-proxy), perform the actual grunt work
derived from the desired state.

![controller events](/assets/img/k8s-controller-manager/kube-controller-manager-events.drawio.png)
_High level view of a small subset of what happens when a new deployment is added._

# In the cloud

In cloud environments, the [cloud-controller-manager](https://kubernetes.io/docs/concepts/architecture/cloud-controller/)
runs alongside the kube-controller-manager. This controller manager operates the same way as the built-in
`kube-controller-manager` in principle, with its control loops tailored specifically for management of cloud
infrastructure. It is this controller manager that handles updates from the cloud provider: nodes automatically entering
or leaving the cluster, provisioning of load balancers, updating IP routes within your cluster, and so on.

# Conclusion

Kubernetes is a distributed system that serves as a platform that automates many of the complexities behind deployment,
scaling, and management of applications. The `kube-controller-manager` implements many critical control loops that
ensure the cluster’s current state matches the user’s desired state. These control loops function independently of each
other, listening for events from the API server and modifying resources there as well. Other components, such as the
`kube-proxy` and the `kubelet` perform the actual runtime configurations on the cluster’s nodes. In cloud environments,
the `cloud-controller-manager` runs alongside the `kube-controller-manager` and implements control loops specific to
cloud infrastructure.

<br/>
<br/>

---

**Footnotes**

[^1]: Components on the _control plane_ observe and adjust the network's resources, topology, and routing tables in accordance with the desired state. See [Wikipedia's article](https://en.wikipedia.org/wiki/Control_plane) on the control plane in the context of network routing. In contrast, the [data plane](https://en.wikipedia.org/wiki/Forwarding_plane#Data_plane) is the part of a system that processes the actual traffic flowing through the network. Interestingly enough, Kubernetes does not have any components in the data plane. We already noted in a [previous article](/posts/k8s-cluster-network) how `kube-proxy` does not reside in this plane. Instead, it is a "Node Component" that configures IP routing rules on the local node. The local node's network stack is in the data plane, `kube-proxy` is not.
[^2]: These "watches" are based on etcd3's [Watch API](https://etcd.io/docs/v3.2/learning/api/#watch-api). Breadcrumbs: [registerResourceHandlers](https://github.com/kubernetes/apiserver/blob/870a2c4b33dc177451466443bfe2d083547bc0c3/pkg/endpoints/installer.go#L809) -> [restulListResource](https://github.com/kubernetes/apiserver/blob/870a2c4b33dc177451466443bfe2d083547bc0c3/pkg/endpoints/installer.go#L1261) -> [ListResource](https://github.com/kubernetes/apiserver/blob/aa161f2fc0887a6665d34f3416d5fa4e69f8e0e4/pkg/endpoints/handlers/get.go#L267) -> -[serveWatch](https://github.com/kubernetes/apiserver/blob/a414002089050e74f0e2b9f379ed359f63bd469e/pkg/endpoints/handlers/watch.go#L138) -> [WatchServer.ServeHTTP](https://github.com/kubernetes/apiserver/blob/a414002089050e74f0e2b9f379ed359f63bd469e/pkg/endpoints/handlers/watch.go#L237-L279). Stepping back in reverse order, we see how the etcd3 watch is wired in: [ListResource](https://github.com/kubernetes/apiserver/blob/aa161f2fc0887a6665d34f3416d5fa4e69f8e0e4/pkg/endpoints/handlers/get.go#L260) -> [restfulListResource](https://github.com/kubernetes/apiserver/blob/870a2c4b33dc177451466443bfe2d083547bc0c3/pkg/endpoints/installer.go#L1261) -> [registerResourceHandlers](https://github.com/kubernetes/apiserver/blob/870a2c4b33dc177451466443bfe2d083547bc0c3/pkg/endpoints/installer.go#L335); implementations of `rest.Watcher.Watch()` include [Store.Watch](https://github.com/kubernetes/apiserver/blob/27cf1d8797a919a081977c11bdcc6821de1ee341/pkg/registry/generic/registry/store.go#L1275) -> [Store.WatchPredicate](https://github.com/kubernetes/apiserver/blob/27cf1d8797a919a081977c11bdcc6821de1ee341/pkg/registry/generic/registry/store.go#L1292) -> [DryRunnableStorage.Watch](https://github.com/kubernetes/apiserver/blob/902be897080a23413399129a67a2f552b0e0fd60/pkg/registry/generic/registry/dryrun.go#L60); implementations of `storage.Interface.Watch()` include [etcd3.store.Watch](https://github.com/kubernetes/apiserver/blob/3f56cdd970302d9c684e36b60a23da6939592aad/pkg/storage/etcd3/store.go#L874) -> [etcd3.watcher.Watch](https://github.com/kubernetes/apiserver/blob/499bbb88dc8e01e4af608afeb5907556a73ca1ba/pkg/storage/etcd3/watcher.go#L113-L114).
