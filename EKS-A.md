# EKS Anywhere (EKS-A) Architecture and Installation

This document provides a detailed overview of **Amazon EKS Anywhere (EKS-A)**, its architecture, key components, and installation options.

---

## Table of Contents

1. [Introduction](#introduction)
2. [High-Level Architecture](#high-level-architecture)
3. [Control Plane Components](#control-plane-components)
4. [Worker Node Components](#worker-node-components)
5. [Networking in EKS-A](#networking-in-eks-a)
6. [Storage and Data Management](#storage-and-data-management)
7. [Add-ons and Integrations](#add-ons-and-integrations)
8. [Cluster Lifecycle Management](#cluster-lifecycle-management)
9. [Installation Options](#installation-options)
10. [References](#references)

---

## Introduction

**EKS Anywhere (EKS-A)** allows organizations to create **Kubernetes clusters on-premises** or in custom environments while leveraging EKS features.

It provides:

* Consistent Kubernetes experience across on-premises and AWS cloud.
* Simplified cluster lifecycle management: creation, upgrades, and deletion.
* Support for VMware vSphere, bare metal servers, and cloud hybrid setups.

---

## High-Level Architecture

```
                ┌─────────────────────────┐
                │   Management Cluster    │
                └─────────────┬──────────┘
                              │
               ┌──────────────┴──────────────┐
               │       EKS-A Cluster         │
               └─────────────┬──────────────┘
                             │
             ┌───────────────┴───────────────┐
             │                               │
      ┌──────┴──────┐                  ┌─────┴─────┐
      │ Control     │                  │ Worker    │
      │ Plane Nodes │                  │ Nodes     │
      └─────────────┘                  └───────────┘
```

* **Management Cluster**: Temporary cluster to bootstrap EKS-A operations.
* **Control Plane Nodes**: Masters running `kube-apiserver`, `etcd`, `kube-scheduler`, `kube-controller-manager`.
* **Worker Nodes**: Run user workloads.
* **Add-ons**: Optional components for monitoring, logging, and networking.

---

## Control Plane Components

| Component                   | Description                                        |
| --------------------------- | -------------------------------------------------- |
| **kube-apiserver**          | API endpoint for cluster operations.               |
| **etcd**                    | Cluster state storage.                             |
| **kube-scheduler**          | Assigns workloads to nodes.                        |
| **kube-controller-manager** | Maintains cluster state.                           |
| **Cluster API**             | EKS-A layer for upgrades, scaling, reconciliation. |

---

## Worker Node Components

| Component             | Description                     |
| --------------------- | ------------------------------- |
| **kubelet**           | Manages pods on the node.       |
| **kube-proxy**        | Routes service traffic.         |
| **Container Runtime** | Docker, containerd, or CRI-O.   |
| **Monitoring Agents** | Metrics collection and logging. |

---

## Networking in EKS-A

* **CNI Plugins**: e.g., Calico, Cilium.
* **Pod and Service CIDRs** for IP allocation.
* **Load Balancers** for external access.
* **Cluster DNS** via CoreDNS.

---

## Storage and Data Management

* **Persistent Volumes (PVs)** and **Persistent Volume Claims (PVCs)**.
* **CSI Drivers** for on-prem storage.
* **etcd backup and restore** using EKS-A CLI.

---

## Add-ons and Integrations

* **Cluster Autoscaler** for scaling worker nodes.
* **Metrics Server** for resource metrics.
* **Observability Tools**: Prometheus, Grafana, Fluent Bit.
* **Optional AWS integrations** for hybrid setups.

---

## Cluster Lifecycle Management

* **Create Cluster**: `eksctl anywhere create cluster -f spec.yaml`
* **Upgrade Cluster**: `eksctl anywhere upgrade cluster`
* **Scale Cluster**: Adjust worker node count in the config YAML.
* **Delete Cluster**: `eksctl anywhere delete cluster -f spec.yaml`

---

## Installation Options

EKS Anywhere supports **multiple deployment options** depending on infrastructure:

### 1. VMware vSphere

* Requires vSphere 7.0 or later.
* Control plane and worker nodes are provisioned as VMs.
* Supports HA configuration for control plane nodes.
* Recommended for enterprises with existing VMware infrastructure.

### 2. Bare Metal / Local Servers

* Nodes are physical servers with a supported OS (Ubuntu 20.04+, Rocky Linux 8+).
* Requires DHCP, DNS, and network connectivity between nodes.
* Ideal for environments with no virtualization layer.

### 3. Hybrid Cloud (Optional AWS Integration)

* Combine on-prem clusters with AWS EKS clusters.
* Use AWS services like S3, IAM, or CloudWatch for specific integrations.

### 4. Management Cluster Options

* **Kind-based Management Cluster**: Lightweight Kubernetes cluster used for bootstrap.
* **Existing Management Cluster**: You can reuse an existing cluster to manage EKS-A clusters.

### Installation Steps (General)

1. Install prerequisites:

   * `eksctl-anywhere` CLI
   * `kubectl`
   * `docker` or `containerd`
   * vSphere CLI or SSH access for bare metal
2. Prepare infrastructure (VMs or physical nodes).
3. Define cluster configuration in a YAML file:

   ```yaml
   apiVersion: anywhere.eks.amazonaws.com/v1alpha1
   kind: Cluster
   metadata:
     name: my-cluster
   spec:
     controlPlaneConfiguration:
       count: 3
     workerNodeGroupConfigurations:
       - name: worker-group-1
         count: 3
   ```
4. Create cluster:

   ```bash
   eksctl anywhere create cluster -f cluster-spec.yaml
   ```
5. Install add-ons as needed.

---

## References

* [EKS Anywhere Documentation](https://aws.amazon.com/eks/eks-anywhere/)
* [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)
* [Cluster API Project](https://cluster-api.sigs.k8s.io/)
