---
layout: post
title: "Understanding Kubernetes' Cluster Networking"
date: 2022-12-30 14:00:00 -0500
author: George Aristy
math: on
tags:
- kubernetes
- k8s
- iptables
- networking
- proxy
- kube-proxy
---

![cover](/assets/img/Kubernetes-icon-color.svg){: .left width="100" }
[Kubernetes](https://kubernetes.io/) is a system for automating deployment, scaling, and management of containerized
applications.
[Networking is a central part of Kubernetes](https://kubernetes.io/docs/concepts/cluster-administration/networking/),
and in this article we will explore how Kubernetes configures the cluster to handle
[east-west traffic](https://kubernetes.io/docs/concepts/cluster-administration/networking/). We'll reserve discussion
on north-south traffic for a later article.

# Introduction

By default, all pods in a K8s cluster can communicate with each other without
[NAT](https://en.wikipedia.org/wiki/Network_address_translation) ([source](https://kubernetes.io/docs/concepts/services-networking/))[^1],
therefore each pod is assigned a cluster-wide IP address. Containers within each pod share the pod's network namespace,
allowing them to communicate with each other on `localhost` via the `loopback` interface. From the point of view of
the workloads running inside the containers, this IP network looks like any other and no changes are necessary.

![k8s-pod-container-network](/assets/img/k8s-networking/k8s-pod-container-network.svg)
_Simplified view of inter-Pod and intra-Pod network communication._

Recall from a previous article that as far as K8s components go, the
[kubelet and the kube-proxy](/posts/kubernetes-in-action/#node-components) are responsible for creating pods and applying 
network configurations on the cluster's nodes. When the pod is being created or terminated, part of the `kubelet`'s job
is to set up or cleanup the pod's sandbox on the node it is running on. The `kubelet` relies on the
[`Container Runtime Interface`](https://github.com/kubernetes/cri-api) (CRI) implementation to handle the details of creating
and destroying sandboxes. The CRI is composed of several interfaces, but for the topic of this article we will focus on the
[`PodSandboxManager`](https://github.com/kubernetes/cri-api/blob/adbbc6d75b383d6b823c24bba946029458d6681b/pkg/apis/services.go#L67-L85)
interface. On the other hand, `kube-proxy` configures routing rules to proxy traffic directed at
[`Services`](https://kubernetes.io/docs/concepts/services-networking/service/) and to perform simple load-balancing between
the corresponding [`Endpoints`](https://kubernetes.io/docs/concepts/services-networking/service/#endpoints). Note that
`kube-proxy` is itself not actually in the request path (_data plane_).
A third component - [`coreDNS`](https://github.com/coredns/coredns) - resolves network names by looking them up in 
`etcd`.

![k8s-pod-sandbox-network](/assets/img/k8s-networking/k8s-cri-network.svg)
_Components involved in the network configuration for a pod. Blue circles are pods and orange rectangles are daemons.
Note that `etcd` is shown here as a database service, but it is also deployed as a pod._

Let's dive into how everything is set up such that a message from a container in a pod can reach a container in another
pod across the network in a different host in a Linux-based cluster.

# Pod-Pod Networking

## The pod's sandbox

Linux has a concept called [namespaces](https://en.wikipedia.org/wiki/Linux_namespaces). Namespaces are a feature that
isolate the resources that a process sees from another processes. For example, a process may see MySQL running with PID
123 but a different process running in a different namespace (but on the same host) will see a different process assigned
to PID 123, or none at all.

There are different kinds of namespaces; we are interested in the [Network (net)](https://en.wikipedia.org/wiki/Linux_namespaces#Network_(net))
namespace.

Each namespace has a logical network interface attached to it, and each _may_ have a virtual network device attached to it.
Each of these virtual devices may be assigned exclusive or overlapping IP address ranges.

### localhost

Processes running inside a `net` namespace can send messages to each other over `localhost`.

![pod-sandbox](/assets/img/k8s-networking/pod-sandbox.svg)
_Traffic from a client to a server inside a network namespace. <font color="blue"><strong>Blue</strong></font> is traffic on `localhost`. Notice the host's interface (`eth0`) is bypassed entirely for this traffic._

With this we have one or more processes that can communicate over `localhost`. This is exactly how pods work, and these
"processes" are K8s containers.

> **Hands On**
>
> Create a `net` namespace with a client and a server:
>
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
>
> ```shell
> # create network namespace
> $ ip netns add client
> $ ip netns list
> client
> # `loopback` is DOWN by default
> $ ip netns exec client ip link list
> 1: lo: <LOOPBACK> mtu 65536 qdisc noqueue state DOWN mode DEFAULT group default qlen 1000
>    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
> # initialize `loopback` (`lo` is shorthand for "loopback")
> $ ip netns exec client ip link set dev lo up
> $ ip netns exec client python3 -m http.server 8080
> Serving HTTP on :: port 8080 (http://[::]:8080/) ...
> 
> # in a separate terminal session:
> $ ip netns exec client curl localhost:8080
> <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
> <html>
> <head>
> <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
> <title>Directory listing for /</title>
> </head>
> <body>
> <h1>Directory listing for /</h1>
> <hr>
> <ul>
> ...
> </ul>
> <hr>
> </body>
> </html>
> ```
>   </div>
> </details>
{: .prompt-tip }

## Pod networking on the same host

Remember that all pods in a K8s cluster can communicate with each other without NAT. So, how would two pods on the same
host communicate with each other? Let's give it a shot. Let's create another namespace and attempt to communicate 
with it.

> **Hands On**
>
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
>
> ```shell
> # create the other pod's network namespace
> $ ip netns add server
> $ ip netns list
> server
> client
> # now stop the server you had running before and restart it, this time in the new `server` namespace
> $ ip netns exec server python3 -m http.server 8080                                                                                                                                                           ✔  11m 17s  20:45:26 
> Serving HTTP on :: port 8080 (http://[::]:8080/) ...
> # now attempt to call this server from the client namespace
> $ ip netns exec client curl localhost:8080                                                                                                                                                                         INT ✘  20:46:48 
> curl: (7) Failed to connect to localhost port 8080 after 0 ms: Connection refused
> ```
>   </div>
> </details>
{: .prompt-tip }

![disconnected-pods](/assets/img/k8s-networking/disconnected-pods.svg)

We don't have an address for `server` from within the `client` namespace yet. All `client` has is `lo` which is
always assigned `127.0.0.1`. We need another interface between these two namespaces for communication to happen.

Linux has the concept of _Virtual Ethernet Devices_ ([veth](https://man7.org/linux/man-pages/man4/veth.4.html)) that act
like "pipes" through which network packets flow, and of which you can attach either end to a namespace or a device. The
"ends" of these "pipes" act as virtual devices to which IP addresses can be assigned. It is perfectly possible to create
a _veth_ device and connect our two namespaces like so:

![pods-veth](/assets/img/k8s-networking/pods-veth.svg)

However, consider that `veth` are _point-to-point_ devices with just two ends, therefore you will need exactly
$$ n(n-1)/2 $$ of these, where $$ n $$ is the number of namespaces. This becomes unwieldy pretty quickly. We will use a
[bridge](https://wiki.linuxfoundation.org/networking/bridge) to solve this problem. A bridge lets us connect any
number of devices to it and it will happily route traffic between them.

> **Hands On**
>
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
>
> ```shell
> # create a bridge
> $ ip link add bridge type bridge
> # bring the bridge up
> $ ip link set bridge up
> # create veth pairs
> $ ip link add veth-client type veth peer name veth-clientbr
> $ ip link add veth-server type veth peer name veth-serverbr
> # attach one end of the veth devices to their respective namespaces
> $ ip link set veth-client netns client 
> $ ip link set veth-server netns server 
> # discover the new devices in the client and server namespaces, and bring them up
> $ ip netns exec client ip addr
> 1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
> link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
> 29: veth-client@if28: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
> link/ether b2:7f:b1:48:de:18 brd ff:ff:ff:ff:ff:ff link-netnsid 0
> $ ip netns exec client ip link set dev veth-client up
> $ ip netns exec server ip addr
> 1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
> link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
> 31: veth-server@if30: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
> link/ether da:39:69:ca:49:83 brd ff:ff:ff:ff:ff:ff link-netnsid 0
> $ ip netns exec server ip link set dev veth-server up
> # now connect the other ends of the veth devices to the bridge and bring their devices up
> $ ip link set veth-clientbr master bridge
> $ ip link set veth-clientbr up
> $ ip link set veth-serverbr master bridge
> $ ip link set veth-serverbr up
> # now let's assign IP addresses to the interfaces inside the client and server namespaces
> $ ip netns exec client ip addr add 10.0.0.1/24 dev veth-client
> $ ip netns exec server ip addr add 10.0.0.2/24 dev veth-server
> # let's also assign an IP address to the bridge
> $ ip addr add 10.0.0.0/24 dev bridge
> # test connectivity
> $ ip netns exec client curl -v 10.0.0.2:8080
> <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
> <html>
> <head>
> <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
> <title>Directory listing for /</title>
> </head>
> <body>
> <h1>Directory listing for /</h1>
> <hr>
> <ul>
> ...
> </ul>
> <hr>
> </body>
> </html>
> # you can also ping the bridge device itself:
> $ ip netns exec client ping 10.0.0.0 -c 5
> PING 10.0.0.0 (10.0.0.0) 56(84) bytes of data.
> 64 bytes from 10.0.0.0: icmp_seq=1 ttl=64 time=0.079 ms
> 64 bytes from 10.0.0.0: icmp_seq=2 ttl=64 time=0.080 ms
> 64 bytes from 10.0.0.0: icmp_seq=3 ttl=64 time=0.098 ms
> 64 bytes from 10.0.0.0: icmp_seq=4 ttl=64 time=0.041 ms
> 64 bytes from 10.0.0.0: icmp_seq=5 ttl=64 time=0.074 ms
> 
> --- 10.0.0.0 ping statistics ---
> 5 packets transmitted, 5 received, 0% packet loss, time 4100ms
> rtt min/avg/max/mdev = 0.041/0.074/0.098/0.018 ms
> ```
>   </div>
> </details>
{: .prompt-tip }

At this point the whole setup looks like this:

![pods-bridge](/assets/img/k8s-networking/pods-bridge.svg)
_Two linux `net` namespaces connected to each other via a bridge. Note that although the bridge is connected to the host's
interface (`eth0`), traffic between the namespaces bypasses it entirely._

> Note that your host's IP rules may be dropping packets flowing through the bridge. To troubleshoot this using `iptables`
> on Linux, do the following:
>
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
>
> ```shell
> # let's inspect the `filter` table
> $ iptables -t filter -L -n -v
> Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
> pkts bytes target     prot opt in     out     source               destination
> 
> Chain FORWARD (policy DROP 39 packets, 3108 bytes)
> pkts bytes target     prot opt in     out     source               destination
> 887K 1028M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
> 887K 1028M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
> 0     0 ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
> 0     0 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
> 0     0 ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
> 0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
> 0     0 ACCEPT     all  --  *      br-e19ba5cb25ae  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
> 0     0 DOCKER     all  --  *      br-e19ba5cb25ae  0.0.0.0/0            0.0.0.0/0
> 0     0 ACCEPT     all  --  br-e19ba5cb25ae !br-e19ba5cb25ae  0.0.0.0/0            0.0.0.0/0
> 0     0 ACCEPT     all  --  br-e19ba5cb25ae br-e19ba5cb25ae  0.0.0.0/0            0.0.0.0/0
> ...
> ```
> 
> There are likely no rules matching the traffic arriving at the bridge, so they are being dropped as per the default
> policy on the `FORWARD` chain.
> 
> Add rules to forward packets flowing into and out of the bridge and try connectivity again:
> 
> ```shell
> # our device is named "bridge"
> $ iptables -A FORWARD -o bridge -m comment --comment "allow packets into the bridge"
> $ iptables -A FORWARD -i bridge -m comment --comment "allow packets out of the bridge"
> # there should be two new entries
> $ iptables -t filter -L -n -v
> ...
> Chain FORWARD (policy DROP 39 packets, 3108 bytes)
> pkts bytes target     prot opt in     out     source               destination
> 887K 1028M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
> 887K 1028M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
>  0     0 ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
>  0     0 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
> ...
> 38  8992 ACCEPT     all  --  *      bridge  0.0.0.0/0            0.0.0.0/0            /* allow packets into the bridge */
>  0     0 ACCEPT     all  --  bridge *       0.0.0.0/0            0.0.0.0/0            /* allow packets out of the bridge */
> ...
> ```
> 
> This should hopefully unblock traffic through the bridge and thus between your two namespaces.
>   </div>
> </details>
{: .prompt-info }

## Pod networking between different hosts

The only way in and out of our host in our example above is via the `eth0` interface. For outbound traffic, the packets
first need to reach `eth0` before being forwarded to the physical network. For inbound packets, `eth0` needs to forward
those to the bridge where they will be routed to the respective namespace interfaces. Let's first try outbound traffic.

### Outbound

Let's see if we can reach `eth0` first:

```shell
root@kind-control-plane:/# ip netns exec client ping 172.18.0.2
ping: connect: Network is unreachable
root@kind-control-plane:/# ip netns exec server ping 172.18.0.2
ping: connect: Network is unreachable
```

The host isn't reachable from the namespaces yet. We claimed at the end of the prior section that the `bridge` is already
connected to `eth0`, so what could be the problem? _We haven't configured an IP route to forward packets destined to
`172.18.0.2`._ Let's set up a default route via the bridge in both namespaces and test:

```shell
root@kind-control-plane:/# ip netns exec client ip route add default via 10.0.0.0
root@kind-control-plane:/# ip netns exec server ip route add default via 10.0.0.0
root@kind-control-plane:/# ip netns exec client ping 172.18.0.2 -c 2
PING 172.18.0.2 (172.18.0.2) 56(84) bytes of data.
64 bytes from 172.18.0.2: icmp_seq=1 ttl=64 time=0.076 ms
64 bytes from 172.18.0.2: icmp_seq=2 ttl=64 time=0.039 ms

--- 172.18.0.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1031ms
rtt min/avg/max/mdev = 0.039/0.057/0.076/0.018 ms
root@kind-control-plane:/# ip netns exec server ping 172.18.0.2 -c 2
PING 172.18.0.2 (172.18.0.2) 56(84) bytes of data.
64 bytes from 172.18.0.2: icmp_seq=1 ttl=64 time=0.036 ms
64 bytes from 172.18.0.2: icmp_seq=2 ttl=64 time=0.035 ms

--- 172.18.0.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1031ms
rtt min/avg/max/mdev = 0.035/0.035/0.036/0.000 ms
```

Great, we can now reach our host's interface. By extension, we can also reach any destination reachable from `eth0`:

```shell
root@kind-control-plane:/# ip netns exec client curl https://google.com
<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>301 Moved</TITLE></HEAD><BODY>
<H1>301 Moved</H1>
The document has moved
<A HREF="https://www.google.com/">here</A>.
</BODY></HTML>
root@kind-control-plane:/# ip netns exec server curl https://google.com
<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>301 Moved</TITLE></HEAD><BODY>
<H1>301 Moved</H1>
The document has moved
<A HREF="https://www.google.com/">here</A>.
</BODY></HTML>
```

This flow looks similar to the following when viewed from the `client` flow (the network and machine configuration on
Google's side has been reduced to a simple machine instance to simplify the illustration):

![pods-outbound.svg](/assets/img/k8s-networking/pods-outbound.svg)

Next up, let's try to communicate to a server running inside one of our namespaces from outside.

### Inbound

To test things out, let's first break apart our setup and place the `server` namespace in a different host:

![pod-different-hosts](/assets/img/k8s-networking/pods-diffhosts.svg)
_Namespaces on different hosts. The host interfaces (`eth0`) are on the same network._

Let's first ensure the host interface is reachable from each namespace before proceeding:

```shell
# client namespace
root@kind-control-plane:/# ip netns exec client ping 172.18.0.2 -c 1
PING 172.18.0.2 (172.18.0.2) 56(84) bytes of data.
64 bytes from 172.18.0.2: icmp_seq=1 ttl=64 time=0.104 ms

--- 172.18.0.2 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.104/0.104/0.104/0.000 ms
# server namespace
root@kind-worker:/# ip netns exec server ping 172.18.0.2 -c 1
PING 172.18.0.2 (172.18.0.2) 56(84) bytes of data.
64 bytes from 172.18.0.2: icmp_seq=1 ttl=63 time=0.155 ms

--- 172.18.0.2 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.155/0.155/0.155/0.000 ms
```

With this setup, can `client` reach `server` without NAT (TODO recall kubernetes requirement)? Let's find out:

```shell
# from client namespace
root@kind-control-plane:/# ip netns exec client curl -m 2 10.0.0.2:8080  
curl: (28) Connection timed out after 2001 milliseconds
```

Hmm, it doesn't work. Let's break the problem down a little and try to reach `server` from its own host (Host B):

```shell
root@kind-worker:/# curl 10.0.0.2:8080
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
...
</ul>
<hr>
</body>
</html>
```

That works. The problem appears to lie between the interfaces of both hosts.

<br/>
<br/>

- TODO macvlan instead of veth+bridge: https://unix.stackexchange.com/a/546090/311703
- TODO discuss CNI
- TODO warn about risks while performing commands; better to try in a VM or container or something
- TODO remove all `sudo` since we are now doing the whole exercise in a container/VM
- TODO warn that it's typically not possible to add a wireless interface to a bridge
- TODO when pinging `eth0`, can we instead curl a server running on the host to keep it all uniform?
- TODO say that there are several ways of configuring all this
- TODO make sure echo 1 > /proc/sys/net/ipv4/ip_forward

---

[^1]: You can use the [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) resource (+ a suitable CNI plugin) to block traffic to/from Pods.
[^2]: Wikipedia has a very nice description of the IP routing algorithm [here](https://en.wikipedia.org/wiki/IP_routing#Routing_algorithm).