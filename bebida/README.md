# Introduction

This composition proposes an environment with Bebida implemented on Kubernetes and and OAR.
Bebida is collocation mechanism that allows any dynamic resource management
system (here Kubernetes) to use resources leave idle by an HPC resources
management system (here  OAR). It is siply base on prolog and epilog scripts.
See https://hal.science/hal-01633507/file/bigdata_hpc_colocation.pdf for more
details.

# Main Steps

## Install

First you'll need to install NXC. See main [README](../README.md) for more information about setting.

## Build
```bash
# Go in this repository's directory
cd regale-nixos-compose/bebida
# Build the environment
nxc build -f vm
```

## Deploy on VMs

```bash
export MEM=2048
nxc start
```
Wait for the VM to start, and then in another terminal (in the same directory), you can connect to the frontend with:
```bash
nxc connect frontend
```
Check that OAR has two nodes alive with `oarnodes`:
```bash
[root@frontend:~]# oarnodes -s
node1:
        1: Alive
node2:
        2: Alive
```

On another terminal, connect to the server to check that k3s is also seeing the
nodes as Ready:
```bash
nxc connect server
```

```bash
[root@server:~]# k get nodes
NAME     STATUS   ROLES                  AGE     VERSION
server   Ready    control-plane,master   2m48s   v1.23.6+k3s1
node2    Ready    <none>                 2m36s   v1.23.6+k3s1
node1    Ready    <none>                 2m36s   v1.23.6+k3s1
```

## Use

Now you can use OAR and K3s with Bebida enabled. On the server wtach the k3s
nodes to state with `k get nodes -w`, you should see:
```bash
[root@server:~]# k get nodes -w
NAME     STATUS   ROLES                  AGE     VERSION
server   Ready    control-plane,master   7m35s   v1.23.6+k3s1
node2    Ready    <none>                 7m23s   v1.23.6+k3s1
node1    Ready    <none>                 7m23s   v1.23.6+k3s1
```
Leave it running while on the frontend node you create a simple OAR job
```bash
[root@frontend:~]# oarsub -l nodes=1 hostname
# INFO:  Moldable instance:  1  Estimated nb resources:  1  Walltime:  3600
OAR_JOB_ID=2
```

You will see in the server terminal that the node allocated to the OAR job
becomes unavailable for the Kubernetes workload (SchedulingDisabled) during the
OAR job execution and then comes back in a Ready state:
```
node1    Ready,SchedulingDisabled   <none>                 8m11s   v1.23.6+k3s1
node1    Ready,SchedulingDisabled   <none>                 8m11s   v1.23.6+k3s1
node1    Ready                      <none>                 8m15s   v1.23.6+k3s1
```
