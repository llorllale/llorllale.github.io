---
layout: post
title: Kubernetes In Action
date: 2022-11-26 09:00:00 -0500
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
- cloud-computing
---

![cover](/assets/img/books/k8s-in-action/cover.jpg){: .left height="300" width="200" }
Written by [Marko Lukša](https://www.linkedin.com/in/marko-luk%C5%A1a-a71205/),
[Kubernetes In Action](https://www.manning.com/books/kubernetes-in-action) is a fantastic book covering all operational
aspects of Kubernetes. I find it _very_ hard to think of a better book on the subject. This is the first edition
of the book, published in December 2017, and although dated around the edges and details, Marko's in-depth dive into
the different components that make up Kubernetes and how they work is timeless. I highly recommend this book to anyone
looking for any serious learning of Kubernetes. This book's shelf life is pretty long despite Kubernetes' active
development - I would think it can only be supplanted by the
[second edition coming out early next year](https://www.manning.com/books/kubernetes-in-action-second-edition)[^1].

_Kubernetes In Action_ provided me with solid a theoretical and practical foundation on Kubernetes, enabling me to earn
the [Certified Kubernetes Application Developer](/posts/ckad) badge.

_Check out some other books I've read on the [bookshelf](/bookshelf/)._

# Summary

_Kubernetes In Action_'s roadmap takes us on a journey with the end goal of developing _Kubia_ - a contrived sample application - while exploring
the core concepts of Kubernetes in depth. Beyond the basics, some of the things this book explains are Kubernetes' architecture,
how pods communicate with each other, how to secure your K8S cluster, pod affinity and anti-affinity, tolerations, the API service,
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
> Run `kubectl config view` to view your local configuration:
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

`kubectl` supports [drop-in plugins](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/) since `v1.12`. 
The community has provided many plugins, some of which I find immensely useful. I'll write about these in a future article.

# System components

![components](/assets/img/books/k8s-in-action/components-of-k8s.webp)
_From Chapter 1, section 1.3.3 **Understanding the architecture of a Kubernetes cluster**_

There are two sets of components:

## Control Plane components

These components are in charge of monitoring and responding to events in the cluster.

* The **API server** ([`kube-apiserver`](https://github.com/kubernetes/kubernetes/tree/master/staging/src/k8s.io/apiserver))
  exposes a REST API and is what `kubectl` interacts with then you execute its commands. The other components
  also discover the state of the cluster via the API server.
* The **Controller Manager** ([`kube-controller-manager`](https://github.com/kubernetes/kubernetes/tree/master/staging/src/k8s.io/controller-manager))
  is the control loop that reconciles the cluster's actual state with the desired state.
* The **Scheduler** ([`kube-scheduler`](https://github.com/kubernetes/kubernetes/tree/master/staging/src/k8s.io/kube-scheduler))
  assigns Pods unto nodes for them to run. There are many reasons why a pod may not be scheduled unto nodes and some
  of those reasons can have side effects, such as an automatic scale up of the cluster's node pool. You will probably
  spend a lot of time figuring out the scheduler and looking at Pod event logs at some point or another.
* **etcd** is the distributed key-value store used by most Kubernetes clusters.

## Node components

These are components that run in each node and are used to realize the configurations sent out by the components in the
control plane.

* [`kubelet`](https://github.com/kubernetes/kubernetes/tree/master/staging/src/k8s.io/kubelet) runs containers specified
  in Pod specs and monitors their health.
* [`kube-proxy`](https://github.com/kubernetes/kubernetes/tree/master/staging/src/k8s.io/kube-proxy) is a network proxy
  that implements part of the Kubernetes _Service_ concept. It takes the network rules configured by the control plane components
  and applies them locally to the node's IP routing rules. It has different modes of operation; there is a nice explanation
  [here](https://kubernetes.io/docs/concepts/services-networking/service/#configuration) about its modes.
* `Container Runtime` are what run the containers (eg. docker, containerd).

# Kubernetes Resources

Kubernetes is a massive beast. Here are (almost) all the resources I am aware of as a developer[^6]:

![image](/assets/img/books/k8s-in-action/k8s-config-components.svg)
_Arrows indicate references to the target component._

_Kubernetes In Action_ covers **all** of these objects and more. I am only going to gloss over a handful of the most
important ones.

## Namespace

Don't let its distance and disconnection from other nodes in the diagram above mislead you:
_[namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)_ is one of the most fundamental
concepts in Kubernetes, as it lets developers and administrators separate different resources into logical groups.
For example, environments such as _dev_, _staging_, and _prod_, can reside in different namespaces within the same K8S
cluster. Another popular use of namespaces is to group resources belonging to applications with cross-cutting concerns.

Adding a connection to `Namespace` from every resource that references it would make the diagram unwieldy!

Beyond grouping user resources into logical units, it is important to understand that some built-in resources are
scoped to the namespace they are declared in and others operate across the whole cluster. For those that are _namespaced_,
the `default` namespace is the default if none is specified.

> **Hands On**
> 
> Declaratively set namespace with `metadata.namespace`:
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

_Containers_ are instances of pre-packaged images (or "snapshots") of executable software that can be run on any platform,
including Kubernetes. Pods are what run your application.

The _Pod_ resource is centered in the [diagram above](#kubernetes-resources) because it is the workhorse
of a Kubernetes application deployment. We'll explore most of those other objects in later sections.

> _All roads lead to Pods_.
> 
> -- me

> **Hands On**
> 
> Use `kubectl run` to create and run Pods imperatively:
> 
> <details>
>     <summary markdown="span">Example</summary>
>     <div markdown="1">
> 
> ```shell
> # This pod defines a single container named _nginx_ with container image also _nginx_.
> # The pod's name also happens to be _nginx_.
> $ kubectl run nginx --image=nginx --dry-run=client -o yaml
> apiVersion: v1
> kind: Pod
> metadata:
>   labels:
>     run: nginx
>   name: nginx
> spec:
>   containers:
>   - image: nginx
>     name: nginx
>   dnsPolicy: ClusterFirst
>   restartPolicy: Always
> ```
>   </div>
> </details>
{: .prompt-tip }

Pods are composed of one or more containers; these containers can be divided into three types:

* containers: these are your regular containers that run your application workload.
* [initContainers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/): similar to regular containers
  except that [kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/) runs them first
  before regular containers. All `initContainers` must run successfully for regular containers to be started. Their use case
  is obvious: use them to execute utilities or setup scripts not present in the regular container. Sadly, `kubectl run`
  does not support specifying initContainers, so we have to add them to the Pod's spec manually.
* [ephemeralContainers](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container):
  these containers are added to the pod at runtime when debugging a Pod. They are not part of the Pod's original manifest.

> **Hands On**
> 
> `kubectl run` cannot add `initContainers` to a Pod. You must add them yourself:
>
> <details>
>   <summary markdown="span">Example pod with initContainers</summary>
>   <div markdown="1">
> 
> ```yaml
> apiVersion: v1
> kind: Pod
> metadata:
>   name: my-pod
>   labels:
>     app: nginx
> spec:
>   initContainers:
>     - name: init
>       image: busybox
>       command: ["echo", "<DOCTYPE !html><body><h1>Hello, World!</h1</body>", ">", "/usr/share/nginx/html/index.html"]
>       volumeMounts:
>         - name: content
>           mountPath: /usr/share/nginx/html
>   containers:
>     - name: app
>       image: nginx
>       ports:
>         - containerPort: 80
>       volumeMounts:
>         - name: content
>           mountPath: /usr/share/nginx/html
>   volumes:
>     - name: content
>       emptyDir: {}
> ```
> </div>
> </details>
{: .prompt-tip }

## PersistentVolumeClaims and PersistentVolumes

A `PersistentVolume` provisions storage for use by Pods. They can be created either statically or dynamically.
A `PersistentVolumeClaim` is a request for a `PersistentVolume`. A PVC specifies the amount of storage requested and, if
a suitable PV is found then the PVC is _bound_ to the PV, otherwise a new PV _may_ be provisioned, depending on the PVC's
`StorageClass`. A Pod (or a `PodTemplate`) can reference a PVC and mount it in one or more of its containers.

We'll cover PVs and PVCs in depth in a later article.

## Deployment

[Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) manage the state of a set of one or
more pods. This is important for a number of use cases, such as scaling the number of pods or updating the application
workload's version.

> You describe a desired state in a Deployment, and the Deployment _Controller_ changes the actual state to the desired
> state at a controlled rate.
> 
> -- [Kubernetes/Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

Under the hood a _deployment_ uses a [ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
to manage a set of pods for a given state. The latter deprecates and replaced the old 
[ReplicationController](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/).

> A ReplicaSet's purpose is to maintain a stable set of replica Pods running at any given time. As such, it is often
> used to guarantee the availability of a specified number of identical Pods.
> 
> -- [Kubernetes/ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)

> **Hands On**
> 
> Create a deployment with `kubectl create deploy`:
>
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
> 
> ```shell
> $ kubectl create deploy mydeploy --image=nginx --replicas=2 --dry-run=client -o yaml
> apiVersion: apps/v1
> kind: Deployment
> metadata:
>   labels:
>     app: mydeploy
>     name: mydeploy
> spec:
>   replicas: 2
>   selector:
>     matchLabels:
>       app: mydeploy
> template:
>   metadata:
>   labels:
>     app: mydeploy
>   spec:
>     containers:
>     - image: nginx
>       name: nginx
> ```
> </div>
> </details>
{: .prompt-tip }


## StatefulSet

[StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) are very similar to _Deployments_
with a big distinction: each pod managed by a _StatefulSet_ has a unique persistent identity which you can match to specific
storage _volumes_ (these are described further down). This makes the _StatefulSet_ particularly useful for distributed applications
such as CouchDB, Redis, Hyperledger Fabric, and many others.

**Note:** a [Headless Service](#service) is required for `StatefulSet`s.

> **Note:** `kubectl` does not have a command to create statefulsets.
{: .prompt-tip }

> **Hands On**
> 
> Here's a simple example from the [Kubernetes docs](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#components):
> 
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
> 
> ```yaml
> apiVersion: apps/v1
> kind: StatefulSet
> metadata:
>   name: web
> spec:
>   selector:
>     matchLabels:
>       app: nginx # has to match .spec.template.metadata.labels
>   serviceName: "nginx"
>   replicas: 3 # by default is 1
>   minReadySeconds: 10 # by default is 0
>   template:
>     metadata:
>       labels:
>         app: nginx # has to match .spec.selector.matchLabels
>     spec:
>       terminationGracePeriodSeconds: 10
>       containers:
>       - name: nginx
>         image: registry.k8s.io/nginx-slim:0.8
>         ports:
>         - containerPort: 80
>           name: web
>         volumeMounts:
>         - name: www
>           mountPath: /usr/share/nginx/html
>   volumeClaimTemplates:
>   - metadata:
>       name: www
>     spec:
>       accessModes: [ "ReadWriteOnce" ]
>       storageClassName: "my-storage-class"
>       resources:
>         requests:
>           storage: 1Gi
> ```
>   </div>
> </details>
> 
> Deploying the above in my local `minikube` cluster using `kubectl apply -f <filename>` we can see:
> 
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
> 
> ```shell
> $ kubectl get statefulset web
> NAME   READY   AGE
> web    3/3     80s
> ```
> 
> ```shell
> $ kubectl get po
> NAME    READY   STATUS    RESTARTS   AGE
> web-0   1/1     Running   0          2m53s
> web-1   1/1     Running   0          2m33s
> web-2   1/1     Running   0          2m13s
> ```
>   </div>
> </details>
> 
> If you describe the pods you'll realize each has an associated `PersistentVolumeClaim`:
> 
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
> 
> ```shell
> $ kubectl describe po web-2
> Name:             web-2
> Namespace:        default
> Priority:         0
> Service Account:  default
> Node:             minikube/192.168.49.2
> ...
> Volumes:
>   www:
>     Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
>     ClaimName:  www-web-2
>     ReadOnly:   false
> ...
> ```
>   </div>
> </details>
> 
> And when describing that PVC you'll see it's associated with a unique `PersistentVolume`:
> 
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
> 
> ```shell
> $ kubectl describe pvc www-web-2
> Name:          www-web-2
> Namespace:     default
> ...
> Volume:        pvc-33f94fdb-9e17-4ee6-a2e7-0b10d88699e3
> ...
> Used By:       web-2
> ...
> ```
>   </div>
> </details>
> 
> Scaling the statefulset down does not delete the PVs:
> 
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
> 
> ```shell
> $ kubectl scale statefulset web --replicas 1
> statefulset.apps/web scaled
> $ kubectl get po
> NAME    READY   STATUS    RESTARTS   AGE
> web-0   1/1     Running   0          91m
> $ kubectl get pvc
> NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
> www-web-0   Bound    pvc-bb53c1eb-de59-477f-b82e-606cdfe234ba   1Mi        RWO            standard       91m
> www-web-1   Bound    pvc-e8ea7850-58da-460f-9fb2-315627708cc3   1Mi        RWO            standard       91m
> www-web-2   Bound    pvc-33f94fdb-9e17-4ee6-a2e7-0b10d88699e3   1Mi        RWO            standard       91m
> $ kubectl get pv
> NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS   REASON   AGE
> pvc-33f94fdb-9e17-4ee6-a2e7-0b10d88699e3   1Gi        RWO            Delete           Bound    default/www-web-2   standard                91m
> pvc-bb53c1eb-de59-477f-b82e-606cdfe234ba   1Gi        RWO            Delete           Bound    default/www-web-0   standard                92m
> pvc-e8ea7850-58da-460f-9fb2-315627708cc3   1Gi        RWO            Delete           Bound    default/www-web-1   standard                91m
> ```
>   </div>
> </details>
> 
> Scaling the statefulset back up does not create new PVCs; the existing PVCs are assigned to the pods in order:
> 
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
> 
> ```shell
> $ kubectl scale statefuleset web --replicas 3
> statefulset.apps/web scaled
>  $ kubectl get po
> NAME    READY   STATUS    RESTARTS   AGE
> web-0   1/1     Running   0          96m
> web-1   1/1     Running   0          47s
> web-2   1/1     Running   0          27s
> $ kubectl get pvc
> NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
> www-web-0   Bound    pvc-bb53c1eb-de59-477f-b82e-606cdfe234ba   1Mi        RWO            standard       97m
> www-web-1   Bound    pvc-e8ea7850-58da-460f-9fb2-315627708cc3   1Mi        RWO            standard       97m
> www-web-2   Bound    pvc-33f94fdb-9e17-4ee6-a2e7-0b10d88699e3   1Mi        RWO            standard       96m
> ```
>   </div>
> </details>
{: .prompt-tip }

## HorizontalPodAutoscaler

> Horizontal scaling means that the response to increased load is to deploy more Pods. This is different from vertical
> scaling, which for Kubernetes would mean assigning more resources (for example: memory or CPU) to the Pods that are
> already running for the workload.
> 
> -- [Kubernetes/HorizontalPodAutoscaler Walkthrough](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)

_HPAs_ will update the `.spec.replicas` of _Deployments_ and _StatefulSets_ using metrics collected from the
[Metrics Server](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits),
as input. The _Metrics Server_ is the default source of container metrics for autoscaling pipelines.

> **Note:** Kubernetes does not provide vertical pod autoscalers out of the box[^7]. You can install the
> [autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler) developed within the Kubernetes
> project umbrella, or you may use your K8S provider's offering, such as
> [GKE's Vertical Pod autoscaling](https://cloud.google.com/kubernetes-engine/docs/concepts/verticalpodautoscaler).
> A vertical pod autoscaler will automatically update the Pod's resource
> [requests and limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits).
{: .prompt-tip }

## Service

Exposing services in Kubernetes both within and without would be more cumbersome if not for
[Service](https://kubernetes.io/docs/concepts/services-networking/service/) objects. Pods are not permanent resources;
_Services_ fill in the gap by providing a stable DNS name for a set of Pods. The target pods are selected by matching
labels.

There are four types of services:

* `ClusterIP` (default): the service will only be reachable within the cluster.
* `NodePort`: allocates a port number on every node (`.spec.ports[*].nodePort`) and forwards incoming traffic to the port
  exposed by the service (`.spec.ports[*].port`). _NodePort_ services 
* `LoadBalancer`: exposes the service to traffic originating from outside the cluster. The machinery used to do this
  depends on the platform.
* `ExternalName`: these map DNS names from within the cluster to external names. In other words, the cluster's DNS
  service will return `CNAME` records instead of `A` records for queries targeting the service's name.

There is a special kind of `Service` called a
[Headless Service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) that does not
perform load-balancing and does not provide a single address for the backing Pods. Instead, it serves to list IP addresses
of all the Pods it selects. This type of `Service` are required for [`StatefulSets`](#statefulset).

> **Hands On**
> 
> Use `kubectl create svc` to create services imperatively:
> 
> <details>
>     <summary markdown="span">Example</summary>
>     <div markdown="1">
> 
> ```shell
> # Create a service of type `ClusterIP`
> $ kubectl create svc clusterip mysvc --tcp=8080:7001 --dry-run=client -o yaml
> apiVersion: v1
> kind: Service
> metadata:
>   labels:
>     app: mysvc
>     name: mysvc
> spec:
>   ports:
>   - name: 8080-7001
>     port: 8080
>     protocol: TCP
>     targetPort: 7001
>   selector:
>     app: mysvc
>   type: ClusterIP
> ```
> </div>
> </details>
> 
> The problem with `kubectl create svc` is that you can't specify a `selector`.
> [Services without selectors](https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors)
> have their uses, but you are more likely to want to point your service to a set of pods in your cluster.
> For this use case you can either write the spec manually or use `kubectl expose`.
> 
> <details>
>     <summary markdown="span">Example</summary>
>     <div markdown="1">
> 
> ```shell
> # Expose a deployment named `webapp`. Note the `selector` automatically added:
> $ kubectl expose deploy webapp --type ClusterIP --name mysvc --port 8080 --dry-run=client -o yaml
> apiVersion: v1
> kind: Service
> metadata:
>   labels:
>     app: webapp
> name: mysvc
> spec:
>   ports:
>   - port: 8080
>     protocol: TCP
>     targetPort: 8080
>   selector:
>     app: webapp
>   type: ClusterIP
> ```
> </div>
> </details>
{: .prompt-tip }

## Ingress

> Ingress exposes HTTP and HTTPS routes from outside the cluster to services within the cluster. Traffic routing is
> controlled by rules defined on the Ingress resource.
> 
> -- [Kubernetes/What is Ingress?](https://kubernetes.io/docs/concepts/services-networking/ingress/#what-is-ingress)

An `Ingress` is an L7 proxy tailored for HTTP(S) services, allowing request routing based on simple rules such as
path prefixes[^8]. Note that if you want to expose your services outside your cluster with something other than HTTP, you'd
have to use `Service`s of type `NodePort` or `LoadBalancer`.

> **Hands On**
> 
> Use `kubectl create ing` to create an Ingress imperatively:
> 
> <details>
>     <summary markdown="span">Example</summary>
>     <div markdown="1">
> 
> ```shell
> # Create an Ingress that directs incoming traffic on `www.example.com` to a backend service `webapp` on port 8080:
> $ kubectl create ing myingress --rule="www.example.com/webapp*=webapp:8080" --dry-run=client -o yaml
> apiVersion: networking.k8s.io/v1
> kind: Ingress
> metadata:
>   name: myingress
> spec:
>   rules:
>   - host: www.example.com
>     http:
>       paths:
>       - backend:
>           service:
>             name: webapp
>             port:
>               number: 8080
>         path: /webapp
>         pathType: Prefix
> ```
> </div>
> </details>
{: .prompt-tip }

# Footnotes

[^1]: It appears you can use code **au35luk** to get a <a target="_blank" href="https://github.com/luksa/kubernetes-in-action-2nd-edition#purchasing-the-book">35% discount <i class="fa fa-external-link-alt"></i></a>.
[^3]: Fondly pronounced by many as "cube cuddle".
[^4]: Other ways include a console offered by your cloud provider in cases where Kubernetes is available as a service.
[^5]: We will explore the configuration in depth in a future article - stay tuned.
[^6]: _As a developer_ I am not including objects that I'm not likely to encounter in may day-to-day, such as [`TokenReview`](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/token-review-v1/) or [`EndpointSlice`](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/). These will typically be objects configured by an administrator role, or perhaps are objects managed by the underlying K8S provider, such as GKE.
[^7]: I've never used a _VPA_. That said, they might help size your nodes adequately, or have you consider making your pods more efficient.
[^8]: For more advanced routing you should probably make use of a service mesh such as Istio (see [VirtualService](https://istio.io/latest/docs/reference/config/networking/virtual-service/#VirtualService)), or you can explore the [Gateway API](https://gateway-api.sigs.k8s.io/) that recently [graduated to beta status](https://kubernetes.io/blog/2022/07/13/gateway-api-graduates-to-beta/)!
