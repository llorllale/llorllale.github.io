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
looking for any serious learning of Kubernetes. This book's shelf life is pretty long despite Kubernetes' active
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

# Tools and runtimes

Kubernetes comes in several flavors. "Vanilla" Kubernetes can be installed using
[`kubeadm`](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).
Other flavors, such as [minikube](https://github.com/kubernetes/minikube), make it very easy to install a local
Kubernetes cluster for development purposes.

The primary way to interact with a Kubernetes cluster is with
[`kubectl`](https://kubernetes.io/docs/reference/kubectl/kubectl/)[^3][^4]. You can install it directly using the official
instructions, but other installation means are available, such as with
[`gcloud components install kubectl`](https://cloud.google.com/sdk/gcloud/reference/components/install) if
[GKE](https://cloud.google.com/kubernetes-engine) is your provider.

Normally `kubectl` is automatically configured by your Kubernetes provisioner with the necessary configuration to interact
with the cluster. For example, here is what my configuration looks like after running
[`minikube start`](https://minikube.sigs.k8s.io/docs/start/)[^5]:

> **Hands On**
> 
> View your local configuration:
> 
> <details>
>     <summary markdown="span">Example</summary>
>     <div markdown="1">
> 
> ```shell
> $ kubectl config view
> apiVersion: v1
> clusters:
> - cluster:
>     certificate-authority: /home/llorllale/.minikube/ca.crt
>     extensions:
>     - extension:
>         last-update: Wed, 24 Aug 2022 21:33:37 EDT
>         provider: minikube.sigs.k8s.io
>         version: v1.25.2
>       name: cluster_info
>     server: https://192.168.49.2:8443
>   name: minikube
> contexts:
> - context:
>     cluster: minikube
>     extensions:
>     - extension:
>         last-update: Wed, 24 Aug 2022 21:33:37 EDT
>         provider: minikube.sigs.k8s.io
>         version: v1.25.2
>       name: context_info
>     namespace: default
>     user: minikube
>   name: minikube
> current-context: minikube
> kind: Config
> preferences: {}
> users:
> - name: minikube
>   user:
>     client-certificate: /home/llorllale/.minikube/profiles/minikube/client.crt
>     client-key: /home/llorllale/.minikube/profiles/minikube/client.key
> ```
> </div>
> </details>
{: .prompt-tip }

> TODO talk about kubectl setups and plugins


# Kubernetes Resources

Kubernetes is a massive beast. Here are (almost) all the resources I am aware of as a developer[^6]:

![image](/assets/img/books/k8s-in-action/k8s-config-components.svg)
_Arrows indicate references to the target component._

## Namespace

Don't let its distance and disconnection from other nodes in the diagram above mislead you:
_[namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)_ is one of the most fundamental
concepts in Kubernetes, as it lets developers and administrators separate different resources into logical groups.
For example, environments such as _dev_, _staging_, and _prod_, can reside in different namespaces within the same K8S
cluster. Another popular use of namespaces is to group resources belonging to applications with cross-cutting concerns.

Beyond grouping user resources into logical units, it is important to understand that some built-in resources are
scoped to the namespace they are declared in and others operate across the whole cluster. For those that are _namespaced_,
the `default` namespace is the default if none is specified.

> **Hands On**
> 
> Set namespace with `metadata.namespace`
>
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
> 
> ```yaml
> apiVersion: v1
> kind: Pod
> metadata:
>   name: myapp
>   namespace: mynamespace
> spec:
>   containers:
>     - name: myapp
>       image: nginx
> ```
>   </div>
> </details>
> <br/>
> Set namespace with `kubectl`:
> 
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
> 
> ```shell
> $ kubectl run -n mynamespace myapp --image nginx --dry-run=client -o yaml
> apiVersion: v1
> kind: Pod
> metadata:
>   creationTimestamp: null
>   labels:
>     run: myapp
>   name: myapp
>   namespace: mynamespace
> spec:
>   containers:
>   - image: nginx
>     name: myapp
>     resources: {}
>   dnsPolicy: ClusterFirst
>   restartPolicy: Always
> status: {}
> ```
>   </div>
> </details>
> <br/>
> View all namespaces for a given cluster/context:
> 
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
>
> ```shell
> $ kubectl get ns
> NAME              STATUS   AGE
> default           Active   63d
> istio-system      Active   59d
> kube-node-lease   Active   63d
> kube-public       Active   63d
> kube-system       Active   63d
> ```
>   </div>
> </details>
> <br/>
> List all resources and see which are namespaced and which aren't:
> 
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
> 
> ```shell
> $ kubectl api-resources
> NAME                              SHORTNAMES   APIVERSION                             NAMESPACED   KIND
> bindings                                       v1                                     true         Binding
> componentstatuses                 cs           v1                                     false        ComponentStatus
> configmaps                        cm           v1                                     true         ConfigMap
> endpoints                         ep           v1                                     true         Endpoints
> events                            ev           v1                                     true         Event
> limitranges                       limits       v1                                     true         LimitRange
> namespaces                        ns           v1                                     false        Namespace
> nodes                             no           v1                                     false        Node
> persistentvolumeclaims            pvc          v1                                     true         PersistentVolumeClaim
> persistentvolumes                 pv           v1                                     false        PersistentVolume
> ...
> ```
>   </div>
> </details>
{: .prompt-tip }

## Pod

> _Pods_ are the smallest deployable units of computing that you can create and manage in Kubernetes.
> Pods are composed of one or more containers with shared storage and network resources.
> 
> -- [Kubernetes/Pods](https://kubernetes.io/docs/concepts/workloads/pods/)

_Containers_ are instances of pre-packaged images (or "snapshots") of executable software that can be run on any platform[^2],
including Kubernetes. Pods are what run your application.

The _Pod_ resource is centered in the [diagram above](#kubernetes-resources) because it is the workhorse
of a Kubernetes application deployment. We'll explore most of those other objects in later sections. TODO and later articles?

The following example pod definition was created with `kubectl run nginx --image=nginx --dry-run=client -o yaml`
(with a couple of unnecessary fields removed):

<details>
    <summary markdown="span">Simple Pod definition</summary>
    <div markdown="1">

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: nginx
  name: nginx
spec:
  containers:
  - image: nginx
    name: nginx
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```
</div>
</details>

This pod defines a single container named _nginx_ with container image also _nginx_. The pod's name also happens to be
_nginx_.

Pods are composed of one or more containers; these containers can be divided into three types:

* containers: these are your regular containers that run your application workload.
* [initContainers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/): similar to regular containers
  except that [kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/) runs them first
  before regular containers. All `initContainers` must run successfully for regular containers to be started. Their use case
  is obvious: use them to execute utilities or setup scripts not present in the regular container. Sadly, `kubect run`
  does not support specifying initContainers, so we have to add them to the Pod's spec manually.
* [ephemeralContainers](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container):
  these containers are added to the pod at runtime when debugging a Pod. They are not part of the Pod's original manifest.

<details>
  <summary markdown="span">Example pod with initContainers</summary>
  <div markdown="1">

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  labels:
    app: nginx
spec:
  initContainers:
    - name: init
      image: busybox
      command: ["echo", "<DOCTYPE !html><body><h1>Hello, World!</h1</body>", ">", "/usr/share/nginx/html/index.html"]
      volumeMounts:
        - name: content
          mountPath: /usr/share/nginx/html
  containers:
    - name: app
      image: nginx
      ports:
        - containerPort: 80
      volumeMounts:
        - name: content
          mountPath: /usr/share/nginx/html
  volumes:
    - name: content
      emptyDir: {}
```
</div>
</details>

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
[^2]: TODO is this footnote still needed? I will eventually dabble with this when I start working towards the [CKA](https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/).
[^3]: Fondly pronounced by many as "cube cuddle".
[^4]: Other ways include a console offered by your cloud provider in cases where Kubernetes is available as a service.
[^5]: We will explore the configuration in depth in a future article - stay tuned.
[^6]: _As a developer_ I am not including objects that I typically will not configure, such as TODO. These are usually non-namespaced resources.

The [Open Container Initiative](https://opencontainers.org/) standardizes the formats of container images and runtimes such that container images bundled by one vendor can be executed by the runtime of a different vendor. Kubernetes supports any container runtime that conforms to its [Container Runtime Interface](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-node/container-runtime-interface.md#specifications-design-documents-and-proposals). The Docker runtime was usually the one in use but as of v1.20 was [deprecated](https://kubernetes.io/blog/2020/12/02/dont-panic-kubernetes-and-docker/), with removal finally occurring in v1.24. [You do not need to panic. It's not as dramatic as it sounds.](https://kubernetes.io/blog/2020/12/02/dont-panic-kubernetes-and-docker/)

Apparently, back then with generators, `kubectl run` would create a [`ReplicationController`](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/) to manage the pod's instances. While not outright deprecated, _ReplicationController_ are no longer recommended - use [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) instead.
