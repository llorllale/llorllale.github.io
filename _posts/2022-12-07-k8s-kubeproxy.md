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
_Conceptual view of inter-Pod and intra-Pod network communication._

Recall from a previous article that as far as K8s components go, the
[kubelet and the kube-proxy](/posts/kubernetes-in-action/#node-components) are responsible for creating pods and applying 
network configurations on the cluster's nodes. When the pod is being created or terminated, part of the `kubelet`'s job
is to set up or cleanup the pod's sandbox on the node it is running on. The `kubelet` relies on the
[`Container Runtime Interface`](https://github.com/kubernetes/cri-api) (CRI) implementation to handle the details of creating
and destroying sandboxes. The CRI is composed of several interfaces, but for the topic of this article we will focus on the
[`PodSandboxManager`](https://github.com/kubernetes/cri-api/blob/adbbc6d75b383d6b823c24bba946029458d6681b/pkg/apis/services.go#L67-L85)
interface. On the other hand, `kube-proxy` configures routing rules to proxy traffic directed at
[`Services`](https://kubernetes.io/docs/concepts/services-networking/service/) and to perform simple load-balancing between
the corresponding [`Endpoints`](https://kubernetes.io/docs/concepts/services-networking/service/#endpoints)[^6].
A third component - [`coreDNS`](https://github.com/coredns/coredns) - resolves network names by looking them up in 
`etcd`.

![k8s-pod-sandbox-network](/assets/img/k8s-networking/k8s-cri-network.svg)
_Components involved in the network configuration for a pod. Blue circles are pods and orange rectangles are daemons.
Note that `etcd` is shown here as a database service, but it is also deployed as a pod._

Let's dive into how everything is set up such that a message from a container in a pod can reach a container in another
pod across the network in a different host in a Linux-based cluster.

> I will be using a simple K8s cluster I set up with [`kind`](https://github.com/kubernetes-sigs/kind) in the walkthrough below.
> `kind` creates a docker container per K8s node. You may choose a similar sandbox, machine instances in the cloud, or any
> other setup that simulates at least two host machines connected to the same network.
{: .prompt-info }

# Create your own Pod Network

We will manually create pods on different hosts to gain an understanding of how Kubernetes' networking is configured
under the hood.

## Network namespaces

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

With this we have one or more processes that can communicate over `localhost`. This is exactly how K8s Pods work, and these
"processes" are K8s containers.

> **Hands On**
>
> Create a `net` namespace with a client and a server:
>
> <details>
>   <summary markdown="span">On a host we'll call "client"</summary>
>   <div markdown="1">
>
> ```shell
> # create network namespace
> root@kind-control-plane:/# ip netns add client
> root@kind-control-plane:/# ip netns list
> client
> 
> # `loopback` is DOWN by default
> root@kind-control-plane:/# ip netns exec client ip link list
> 1: lo: <LOOPBACK> mtu 65536 qdisc noqueue state DOWN mode DEFAULT group default qlen 1000
>    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
> 
> # initialize `loopback` (`lo` is shorthand for "loopback")
> root@kind-control-plane:/# ip netns exec client ip link set lo up
> 
> # start the server
> root@kind-control-plane:/# ip netns exec client nohup python3 -m http.server 8080 &
> [1] 29509
> root@kind-control-plane:/# nohup: ignoring input and appending output to 'nohup.out'
> 
> # invoke the server
> root@kind-control-plane:/# ip netns exec client curl -m 2 localhost:8080
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

## Connecting network namespaces on the same host

Remember that all pods in a K8s cluster can communicate with each other without NAT. So, how would two pods on the same
host communicate with each other? Let's give it a shot. Let's create a "server" namespace and attempt to communicate 
with it.

> **Hands On**
>
> <details>
>   <summary markdown="span">On the same "client" host</summary>
>   <div markdown="1">
>
> ```shell
> # create the other pod's network namespace
> root@kind-control-plane:/# ip netns add server
> root@kind-control-plane:/# ip netns list
> server
> client
> 
> # stop the server you had running before and restart it in the new `server` namespace
> root@kind-control-plane:/# ip netns exec server nohup python3 -m http.server 8080 &
> [1] 29538
> root@kind-control-plane:/# nohup: ignoring input and appending output to 'nohup.out'
> 
> # attempt to call this server from the client namespace
> root@kind-control-plane:/# ip netns exec client curl localhost:8080 
> curl: (7) Failed to connect to localhost port 8080 after 0 ms: Connection refused
> ```
>   </div>
> </details>
{: .prompt-tip }

![disconnected-pods](/assets/img/k8s-networking/disconnected-pods.svg)

We don't have an address for `server` from within the `client` namespace yet. These two network namespaces are completely
disconnected from each other. All `client` and `server` have is `localhost` (dev `lo`) which is
always assigned `127.0.0.1`. We need another interface between these two namespaces for communication to happen.

Linux has the concept of _Virtual Ethernet Devices_ ([veth](https://man7.org/linux/man-pages/man4/veth.4.html)) that act
like "pipes" through which network packets flow, and of which you can attach either end to a namespace or a device. The
"ends" of these "pipes" act as virtual devices to which IP addresses can be assigned. It is perfectly possible to create
a _veth_ device and connect our two namespaces like this:

![pods-veth](/assets/img/k8s-networking/pods-veth.svg)

However, consider that `veth` are _point-to-point_ devices with just two ends and, remembering our requirement that all
Pods must communicate with each other without NAT, we would need  $$ n(n-1)/2 $$ _veth_ pairs, where $$ n $$ is the
number of namespaces. This becomes unwieldy pretty quickly. We will use a
[bridge](https://wiki.linuxfoundation.org/networking/bridge) instead to solve this problem. A bridge lets us connect any
number of devices to it and will happily route traffic between them, turning our architecture into a hub-and-spoke and
reducing the number of _veth_ pairs to just $$ n $$.

> **Hands On**
>
> <details>
>   <summary markdown="span">On the "client" host</summary>
>   <div markdown="1">
>
> ```shell
> # create a bridge
> root@kind-control-plane:/# ip link add bridge type bridge
> 
> # create veth pairs
> root@kind-control-plane:/# ip link add veth-client type veth peer name veth-clientbr
> root@kind-control-plane:/# ip link add veth-server type veth peer name veth-serverbr
> 
> # connect one end of the veth devices to the bridge
> root@kind-control-plane:/# ip link set veth-clientbr master bridge
> root@kind-control-plane:/# ip link set veth-serverbr master bridge
> 
> # attach the other end of the veth devices to their respective namespaces
> root@kind-control-plane:/# ip link set veth-client netns client 
> root@kind-control-plane:/# ip link set veth-server netns server 
> 
> # assign IP addresses to the bridge and our new interfaces inside the client and server namespaces
> root@kind-control-plane:/# ip netns exec client ip addr add 10.0.0.1/24 dev veth-client
> root@kind-control-plane:/# ip netns exec server ip addr add 10.0.0.2/24 dev veth-server
> root@kind-control-plane:/# ip addr add 10.0.0.0/24 dev bridge
>
> # bring our devices up
> root@kind-control-plane:/# ip netns exec client ip link set veth-client up
> root@kind-control-plane:/# ip netns exec server ip link set veth-server up
> root@kind-control-plane:/# ip link set veth-clientbr up
> root@kind-control-plane:/# ip link set veth-serverbr up
> root@kind-control-plane:/# ip link set bridge up
> 
> # confirm state of our interfaces:
> # state of client interfaces
> root@kind-control-plane:/# ip netns exec client ip addr
> 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
>     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
>     inet 127.0.0.1/8 scope host lo
>        valid_lft forever preferred_lft forever
>     inet6 ::1/128 scope host
>        valid_lft forever preferred_lft forever
> 16: veth-client@if15: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
>     link/ether 5e:0e:50:4b:f5:32 brd ff:ff:ff:ff:ff:ff link-netnsid 0
>     inet 10.0.0.1/24 scope global veth-client
>        valid_lft forever preferred_lft forever
>     inet6 fe80::5c0e:50ff:fe4b:f532/64 scope link
>        valid_lft forever preferred_lft forever
> 
> # state of server interfaces
> root@kind-control-plane:/# ip netns exec server ip addr
> ...
> 18: veth-server@if17: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
>     link/ether 46:d0:61:5d:7c:9a brd ff:ff:ff:ff:ff:ff link-netnsid 0
>     inet 10.0.0.2/24 scope global veth-server
>        valid_lft forever preferred_lft forever
>     inet6 fe80::44d0:61ff:fe5d:7c9a/64 scope link
>        valid_lft forever preferred_lft forever
> 
> # state of host interfaces
> root@kind-control-plane:/# ip addr     
> ...
> 11: eth0@if12: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
>     link/ether 02:42:ac:12:00:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
>     inet 172.18.0.2/16 brd 172.18.255.255 scope global eth0
>        valid_lft forever preferred_lft forever
>     inet6 fc00:f853:ccd:e793::2/64 scope global nodad
>        valid_lft forever preferred_lft forever
>     inet6 fe80::42:acff:fe12:2/64 scope link
>        valid_lft forever preferred_lft forever
> 14: bridge: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
>     link/ether ba:21:cf:c1:62:52 brd ff:ff:ff:ff:ff:ff
>     inet 10.0.0.0/24 scope global bridge
>        valid_lft forever preferred_lft forever
> 15: veth-clientbr@if16: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master bridge state UP group default qlen 1000
>     link/ether ba:21:cf:c1:62:52 brd ff:ff:ff:ff:ff:ff link-netns client
> 17: veth-serverbr@if18: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master bridge state UP group default qlen 1000
>     link/ether c2:52:97:04:03:2c brd ff:ff:ff:ff:ff:ff link-netns server
> 
> # test connectivity
> root@kind-control-plane:/# ip netns exec client curl -v 10.0.0.2:8080
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

At this point the whole setup looks like this:

![pods-bridge](/assets/img/k8s-networking/pods-bridge.svg)
_Two linux `net` namespaces connected to each other via a bridge. Note that although the bridge is connected to the host's
interface (`eth0`), traffic between the namespaces bypasses it entirely._

We have just connected two network namespaces on the same host.

## Connecting network namespaces on different hosts

The only way in and out of our hosts in our example above is via their `eth0` interface. For outbound traffic, the packets
first need to reach `eth0` before being forwarded to the physical network. For inbound packets, `eth0` needs to forward
those to the bridge where they will be routed to the respective namespace interfaces. Let's first separate our two
namespaces before going further.

### Moving our network namespaces unto different hosts

Let's first clean up everything we've done so far[^7]:

> **Hands On**
> 
> <details>
>   <summary markdown="span">Steps</summary>
>   <div markdown="1">
>
> ```shell
> # delete the namespaces
> root@kind-control-plane:/# ip netns del client
> root@kind-control-plane:/# ip netns del server
>
> # delete the veth and bridge devices
> root@kind-control-plane:/# ip link del veth-client
> root@kind-control-plane:/# ip link del veth-server
> root@kind-control-plane:/# ip link del bridge
> ```
>   </div>
> </details>
{: .prompt-info }

Let's now set up our namespaces in different hosts.

> **Hands On**
>
> Same steps as before except on different hosts with some minor differences:
>
> <details>
>   <summary markdown="span">On the "client" host</summary>
>   <div markdown="1">
>
> ```shell
> root@kind-control-plane:/# ip netns add client
> root@kind-control-plane:/# ip link add bridge type bridge
> root@kind-control-plane:/# ip link add veth-client type veth peer name veth-clientbr
> root@kind-control-plane:/# ip link set veth-client netns client
> root@kind-control-plane:/# ip link set veth-clientbr master bridge
> root@kind-control-plane:/# ip addr add 10.0.0.0/24 dev bridge
> root@kind-control-plane:/# ip netns exec client ip addr add 10.0.0.1/24 dev veth-client
> root@kind-control-plane:/# ip netns exec client ip link set lo up
> root@kind-control-plane:/# ip netns exec client ip link set veth-client up
> root@kind-control-plane:/# ip link set bridge up
> root@kind-control-plane:/# ip link set veth-clientbr up
> ```
>   </div>
> </details>
>
> <details>
>   <summary markdown="span">On the "server" host</summary>
>   <div markdown="1">
>
> ```shell
> root@kind-worker:/# ip netns add server
> root@kind-worker:/# ip link add bridge type bridge
> root@kind-worker:/# ip link add veth-server type veth peer name veth-serverbr
> root@kind-worker:/# ip link set veth-server netns server
> root@kind-worker:/# ip link set veth-serverbr master bridge
> root@kind-worker:/# ip addr add 10.0.0.0/24 dev bridge
> root@kind-worker:/# ip netns exec server ip addr add 10.0.0.2/24 dev veth-server
> root@kind-worker:/# ip netns exec server ip link set lo up
> root@kind-worker:/# ip netns exec server ip link set veth-server up
> root@kind-worker:/# ip link set bridge up
> root@kind-worker:/# ip link set veth-serverbr up
> 
> # run the server
> root@kind-worker:/# ip netns exec server nohup python3 -m http.server 8080 &
> [1] 1314
> nohup: ignoring input and appending output to 'nohup.out'
> ```
>   </div>
> </details>
{: .prompt-info}

![pod-different-hosts](/assets/img/k8s-networking/pods-diffhosts.svg)
_Namespaces on different hosts. The host interfaces (`eth0`) are on the same network._

Now that everything is set up, let's first tackle outbound traffic.

### From our network namespaces to the physical network

First let's see if we can reach `eth0` on each host:

```shell
# on the client host
root@kind-control-plane:/# ip netns exec client ping 172.18.0.2
ping: connect: Network is unreachable

# on the server host
root@kind-worker:/# ip netns exec server ping 172.18.0.4
ping: connect: Network is unreachable
```

The host isn't reachable from the namespaces yet. _We haven't configured an IP route[^2] to forward packets destined to
`172.18.0.2`._ Let's set up a default route via the bridge in both namespaces and test:

```shell
# on client host
root@kind-control-plane:/# ip netns exec client ip route add default via 10.0.0.0
root@kind-control-plane:/# ip netns exec client ping 172.18.0.2 -c 2
PING 172.18.0.2 (172.18.0.2) 56(84) bytes of data.
64 bytes from 172.18.0.2: icmp_seq=1 ttl=64 time=0.076 ms
64 bytes from 172.18.0.2: icmp_seq=2 ttl=64 time=0.039 ms

--- 172.18.0.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1031ms
rtt min/avg/max/mdev = 0.039/0.057/0.076/0.018 ms

# on server host
root@kind-worker:/# ip netns exec server ip route add default via 10.0.0.0
root@kind-worker:/# ip netns exec server ping 172.18.0.4 -c 2
PING 172.18.0.4 (172.18.0.4) 56(84) bytes of data.
64 bytes from 172.18.0.4: icmp_seq=1 ttl=64 time=0.036 ms
64 bytes from 172.18.0.4: icmp_seq=2 ttl=64 time=0.035 ms

--- 172.18.0.4 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1031ms
rtt min/avg/max/mdev = 0.035/0.035/0.036/0.000 ms
```

Great, we can now reach our host interfaces. By extension, we can also reach any destination reachable from `eth0`:

```shell
# on client host
root@kind-control-plane:/# ip netns exec client curl https://google.com
<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>301 Moved</TITLE></HEAD><BODY>
<H1>301 Moved</H1>
The document has moved
<A HREF="https://www.google.com/">here</A>.
</BODY></HTML>

# on server host
root@kind-worker:/# ip netns exec server curl https://google.com
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

Next up, let's try to communicate to our server from the `client` namespace.

### From the physical network to our network namespaces

If we try to reach `server` from `client` we can see that it doesn't work:

```shell
root@kind-control-plane:/# ip netns exec client curl -m 2 10.0.0.2:8080
curl: (28) Connection timed out after 2001 milliseconds
```

Let's dig in with `tcpdump`.

Open a terminal window and, since we aren't sure what path the packets are flowing through, run `tcpdump -nn -e -l -i any`
on host `172.18.0.2`. **Friendly warning:** the output will be very verbose because `tcpdump` will listen on _all_ interfaces.

On the same host `172.18.0.2`, try to curl the server from the `client` namespace again with
`ip netns exec client curl -m 2 10.0.0.2:8080`. After it times out again, stop `tcpdump` by pressing `Ctrl+C` and review
the output. Search for `10.0.0.2`, our destination address. You should spot some lines like the following:

```
15:05:35.754605 bridge Out ifindex 5 a6:93:c7:0c:96:b2 ethertype ARP (0x0806), length 48: Request who-has 10.0.0.2 tell 10.0.0.0, length 28
15:05:35.754608 veth-clientbr Out ifindex 6 a6:93:c7:0c:96:b2 ethertype ARP (0x0806), length 48: Request who-has 10.0.0.2 tell 10.0.0.0, length 28
```

You may see several of these requests with no corresponding reply[^3].

These are [ARP](https://en.wikipedia.org/wiki/Address_Resolution_Protocol) requests, and the reason they're being fired off
is that there is no [IP ([layer 3](https://en.wikipedia.org/wiki/Network_layer))] route between the `client` and `server`
namespaces. It is possible to
[manually configure ARP entries](https://www.xmodulo.com/how-to-add-or-remove-static-arp-entry-on-linux.html) and implement
["proxy-ARP"](https://tldp.org/HOWTO/Adv-Routing-HOWTO/lartc.bridging.proxy-arp.html) to connect `client` and `server`
at [Layer 2](https://en.wikipedia.org/wiki/Data_link_layer), but we are not doing that today. Kubernetes' networking model
is built on Layer 3 and up, and so must our solution.

We will configure IP routing[^2] rules to route `client` traffic to `server`. Let's first configure a manual route for `10.0.0.2`
on the client host:

```shell
# on client host
root@kind-control-plane:/# ip route add 10.0.0.2 via 172.18.0.4

# validate
root@kind-control-plane:/# curl 10.0.0.2:8080
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

As you can see, `curl`'ing our server API in the `server` namespace from the client _host_ now works[^4].

Let's try `curl`'ing the server from the `client` _namespace_ again:

```shell
root@kind-control-plane:/# ip netns exec client curl -m 2 10.0.0.2:8080
curl: (28) Connection timed out after 2001 milliseconds
```

Another dump with `tcpdump` reveals the same unanswered `ARP` requests as before. Why aren't there responses to these
considering we've successfully established a connection from the client _host_ to the `server` namespace? One reason is
that the connection was made at layer 3 (IP route), but `ARP` is a layer 2 protocol, and as per the
[OSI model's](https://en.wikipedia.org/wiki/OSI_model) semantics, lower-level protocols cannot depend on higher-level ones.
Another reason is that `ARP` messages only reach devices directly connected to our network interface, in this case `eth0`:
the latter's `ARP` table does not contain an entry for `10.0.0.2` even though its namespace's _IP routing_ table does.

The layer 3 solution for us is simple: establish another IP route for `10.0.0.2` inside the `client` namespace[^5]:

```shell
root@kind-control-plane:/# ip netns exec client ip route add 10.0.0.2 via 10.0.0.0
```

You can now verify that calling `server` from `client` works:

```shell
root@kind-control-plane:/# ip netns exec client curl -m 2 10.0.0.2:8080
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

**Congratulations** - we have just manually created two Pods (`net` namespaces) on different hosts, with one container
(aka "process"; `curl` in our case) in one Pod invoking an API in a container in the other Pod without NAT.

![pod-pod-hosts](/assets/img/k8s-networking/pod2pod-diff-hosts.svg)
_A process inside a `client` namespace connecting to an open socket on a `server` namespace in another host. The client
process does not perform any NAT._

# Tying it all together


<br/>
<br/>

- TODO macvlan instead of veth+bridge: https://unix.stackexchange.com/a/546090/311703
- TODO discuss CNI
- TODO warn about risks while performing commands; better to try in a VM or container or something
- TODO warn that it's typically not possible to add a wireless interface to a bridge
- TODO say that there are several ways of configuring all this
- TODO make sure echo 1 > /proc/sys/net/ipv4/ip_forward
- TODO talk about Services and virtual IPs
- TODO don't forget about DNS

---

[^1]: You can use the [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) resource (+ a suitable CNI plugin) to block traffic to/from Pods.
[^2]: Wikipedia has a very nice description of the IP routing algorithm [here](https://en.wikipedia.org/wiki/IP_routing#Routing_algorithm).
[^3]: A reply would look like this: `14:47:51.365200 bridge In  ifindex 5 06:82:91:69:f0:36 ethertype ARP (0x0806), length 48: Reply 10.0.0.1 is-at 06:82:91:69:f0:36, length 28`
[^4]: If you capture another dump with `tcpdump` you'll notice an absence of `ARP` requests for `10.0.0.2`. This is because the route forwards the traffic to `172.18.0.4`, and the MAC address for the latter is already cached in the host's ARP table.
[^5]: In reality, Kubernetes does this in a more efficient way by configuring IP routes for IP _ranges_ (segments) instead of specific addresses. You can verify IP routes on a host with `ip route list`. In my case, I could see that Kubernetes has routed `10.244.1.0/24` via `172.18.0.4` (our "server" host) and `10.244.2.0/24` via `172.18.0.3` (a third node not relevant to our discussion).
[^6]: Note that `kube-proxy` is itself not actually in the request path (_data plane_).
[^7]: Don't worry too much: the changes done so far are not persistent across system restarts.