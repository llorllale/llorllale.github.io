---
layout: post
title: Plugins I use with <code class="highlight">kubectl</code>
date: 2022-11-28 15:40:00 -0500
author: George Aristy
tags:
- kubernetes
- k8s
- kubectl
---

[`kubectl`](https://kubernetes.io/docs/reference/kubectl/) is the official tool to query and run changes on a
Kubernetes cluster and provides a powerful and extensible CLI interface. There are many alternative tools out there
that do a similar job (some with GUIs); I deliberately stick with `kubectl` on my road to master Kubernetes, which
means I try not to hide too much of the complexity in the hopes of burning them into my mind. Sometimes though, there
are actions that are far too elaborate or complicated considering the number of times I need to execute them. Other times,
I just wish the tool itself offered some slight quality of life improvements to the overall experience.

Following are the plugins I personally use all the time to scratch some of my itches with daily use of `kubectl`. Before
we go into those, let's first quickly go over a few productivity hacks:

# Productivity Hacks

## Aliasing

Considering how many times a day I run a command with `kubectl`, I estimate aliasing this command probably saves me
hundreds of keystrokes per day.

Alias `kubectl` to a shorter string that is meaningful to you. I use `k` and honestly it's probably **the** convention
at this point:

```shell
$ alias k=kubectl
$ k get po
NAME    READY   STATUS    RESTARTS      AGE
web-0   1/1     Running   1 (94s ago)   2d15h
...
```

## Shortnames

Familiarize yourself with the short names of the resource definitions recognized by your cluster:

```shell
# compare this:
$ k get replicationcontrollers
# to this:
$ k get rc
```

Note that not all resources have shortnames.

> You can use the `api-resources` command to see the shortnames available for the resource definitions in your
> cluster:
> 
> <details>
>   <summary markdown="span">Example</summary>
>   <div markdown="1">
> 
> ```shell
> $ k api-resources
> NAME                              SHORTNAMES   APIVERSION                             NAMESPACED   KIND
> bindings                                       v1                                     true         Binding
> componentstatuses                 cs           v1                                     false        ComponentStatus
> configmaps                        cm           v1                                     true         ConfigMap
> endpoints                         ep           v1                                     true         Endpoints
> events                            ev           v1                                     true         Event
> limitranges                       limits       v1                                     true         LimitRange
> namespaces                        ns           v1                                     false        Namespace
> ...
> ```
>   </div>
> </details>
{: .prompt-tip }

## Dry runs

[`kubectl create`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#create) and 
[`kubectl run`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#run) have the options
`--dry-run` that I find very useful for quickly sketching the basis for a resource I want to create when I set
the output to yaml format:

```shell
$ k create deploy mydeploy --image=nginx --replicas=3 --dry-run=client -o yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: mydeploy
  name: mydeploy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mydeploy
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: mydeploy
    spec:
      containers:
      - image: nginx
        name: nginx
        resources: {}
status: {}
```

You can pipe that output to a file and make additional tweaks there. Bonus points if instead you patch the output directly
with [`kubectl patch`](https://jamesdefabia.github.io/docs/user-guide/kubectl/kubectl_patch/) (advanced).

## Autocompletion

Enable autocompletion for your shell:

* [bash](https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/)
* [zsh](https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-zsh/)

# Plugins

## krew

Plugins can be "installed" to `kubectl` simply by placing the binary in your `$PATH` and adding the `kubectl-` prefix.
It's as simple as:

```shell
# '~/bin` is in my $PATH
$ printf '#!/bin/bash\n\necho $1' > ~/bin/kubectl-echo
$ chmod +x ~/bin/kubectl-echo
$ k echo 'Hello World!'
Hello World!
```

If you want to avoid the hassle of placing the executables in the correct path, and/or if you would like a tool that
can list plugins from a central repository and automatically install those for you, then [Krew](https://github.com/kubernetes-sigs/krew/)
is for you.

`Krew` is a package manager maintained by the Kubernetes Special Interest Group (SIG) _CLI_ and can do all of this for you:

```shell
# List all plugins in the repo:
$ k krew search
NAME                            DESCRIPTION                                         INSTALLED
access-matrix                   Show an RBAC access matrix for server resources     no
accurate                        Manage Accurate, a multi-tenancy controller         no
advise-policy                   Suggests PodSecurityPolicies and OPA Policies f...  no
advise-psp                      Suggests PodSecurityPolicies for cluster.           no
...

# Show info for a plugin:
$ k krew info advise-policy
NAME: advise-policy
INDEX: default
URI: https://github.com/sysdiglabs/kube-policy-advisor/releases/download/v1.0.2/kube-policy-advisor_v1.0.2_linux_amd64.tar.gz
SHA256: 2d3968fd80d6fe40976dbc86655ef8fe3e6ea4bcb0c43fafb99a39000daa549f
VERSION: v1.0.2
HOMEPAGE: https://github.com/sysdiglabs/kube-policy-advisor
DESCRIPTION: 
Suggests PSPs and OPA Policies based on the required capabilities of the currently running
workloads or a given manifest.

# Install a plugin:
$ k krew install advise-policy
Updated the local copy of plugin index.
Installing plugin: advise-policy
Installed plugin: advise-policy
\
 | Use this plugin:
 |      kubectl advise-policy
 | Documentation:
 |      https://github.com/sysdiglabs/kube-policy-advisor
/
WARNING: You installed plugin "advise-policy" from the krew-index plugin repository.
   These plugins are not audited for security by the Krew maintainers.
   Run them at your own risk.
   
# List installed plugins:
$ k krew list
advise-policy
ctx
krew
ns
...
```

## ctx

[ctx](https://github.com/ahmetb/kubectx/) is a simple plugin to switch between contexts (clusters) with `kubectl`. This
is a great timesaver when you constantly have to switch between different contexts (clusters). You can install it
with `k krew install ctx`.

View configured contexts:

The normal way:

```shell
$ k config get-contexts
CURRENT   NAME       CLUSTER    AUTHINFO   NAMESPACE
*         myclusterA myclusterA myclusterA default
          myclusterB myclusterB myclusterB default
          myclusterC myclusterC myclusterC default
```

Using `ctx`:

```shell
$ k ctx
myclusterA
myclusterB
myclusterC
```

Switch context:

The normal way:

```shell
$ k config set-context myclusterA
Context "myclusterA" modified.
```

Using `ctx`:

```shell
$ k ctx myclusterA
Switched to context "myclusterA".
```

## ns

[ns](https://github.com/ahmetb/kubectx/) is a sibling of [`ctx`](#ctx) with a very similar purpose: it allows you
to easily list and change between namespaces. This is another big timesaver. You can install it with `k krew install ns`.

List namespaces:

The normal way:

```shell
$ k get ns
NAME              STATUS   AGE
default           Active   116d
gcp-auth          Active   34d
istio-system      Active   112d
istioinaction     Active   112d
kube-node-lease   Active   116d
kube-public       Active   116d
kube-system       Active   116d
```

Using `ns`:

```shell
$ k ns
default
gcp-auth
istio-system
istioinaction
kube-node-lease
kube-public
kube-system
```

Switching namespaces (this is a big one):

The normal way:

```shell
$ k config set-context --current --namespace=kube-public
Context "myclusterA" modified.
```

Using `ns`:

```shell
$ k ns kube-public
Context "myclusterA modified.
Active namespace is "kube-public".
```

## tail

[`tail`](https://github.com/boz/kail) is a great plugin for streaming logs from pods. It extends the builtin `kubectl logs`
functionality with the ability to figure out the labels of the pods for you when you point it to a `Service` or a controller.
You can install it with `k krew install tail`.

Example:

```shell
$ k create deploy mydeploy --image=mysql:latest
deployment.apps/mydeploy created
$ k tail -d mydeploy
kube-public/mydeploy-d8c5f59cc-xjdn2[mysql]: 2022-11-28 20:10:32+00:00 [Note] [Entrypoint]: Entrypoint script for MySQL Server 8.0.31-1.el8 started.
kube-public/mydeploy-d8c5f59cc-xjdn2[mysql]: 2022-11-28 20:10:32+00:00 [Note] [Entrypoint]: Switching to dedicated user 'mysql'
kube-public/mydeploy-d8c5f59cc-xjdn2[mysql]: 2022-11-28 20:10:32+00:00 [Note] [Entrypoint]: Entrypoint script for MySQL Server 8.0.31-1.el8 started.
...
```

Another awesome feature is that it does **not** require `RUNNING` pods - it just keeps listening for any pods with the
matching criteria. This is unlike `kubectl logs -f` which fails if there are no matching `RUNNING` pods. This is
great when you don't want to waste time waiting for the deployment to be live to finally execute a command that
tails the logs.

## deprecations

[`deprecations`](https://github.com/rikatz/kubepug) lists all standard K8S resources found in your cluster that are
deprecated (as found in Kubernetes'
[OpenAPI spec](https://github.com/kubernetes/kubernetes/blob/525280d285c4bb4970e571a1e13a601befd75434/api/openapi-spec/swagger.json)).
This is a handy tool that helps you keep your cluster and resources up-to-date. You can install it with `k krew install deprecations`.

```shell
$ k deprecations
W1128 15:24:46.214313  450713 warnings.go:70] v1 ComponentStatus is deprecated in v1.19+
RESULTS:
Deprecated APIs:

ComponentStatus found in /v1
         ├─ ComponentStatus (and ComponentStatusList) holds the cluster validation info. Deprecated: This API is deprecated in v1.19+
                -> GLOBAL: scheduler 
                -> GLOBAL: controller-manager 
                -> GLOBAL: etcd-0 


Deleted APIs:

```

## safe

Do you sometimes feel your spidey sense tingling and your palms sweating a little bit as you constantly switch between
contexts (`k ctx`) and namespaces (`k ns`) while you query the cluster and modify resources? Have you ever thought that
maybe you're being a bit too cavalier with your k8s-foo and should probably slow down and double-check the command you're
about to run before you hit `Enter`? `safe`](https://github.com/rumstead/kubectl-safe) is here to assuage your fears.
You can install it with `k krew install safe`.

```shell
# Alias to ensure you're always SAFE:
$ alias k=kubectl safe
# Queries work as usual:
$ k get po
# Changes must be acknowledged however:
$ k create deploy mydeploy --image=nginx
You are running a create against context myclusterA, continue? [yY]
```

## kubecolor

[`kubecolor`](https://github.com/hidetatz/kubecolor) replaces `kubectl` and colorizes the output[^1]. Since it's a
replacement binary, you cannot install it with `krew` - you either
[download a prebuilt binary or build it yourself](https://github.com/hidetatz/kubecolor#installation).

Examples:

![ns](/assets/img/kubectl-plugins/kubecolor-ns.png)

![top](/assets/img/kubectl-plugins/kubecolor-top.png)

# Footnotes

[^1]: Make sure you install from [this fork/branch](https://github.com/prune998/kubecolor/tree/prune/ctx-no-color) to fix compatibility issues with `ctx` and `ns`.