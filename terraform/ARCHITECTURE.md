# EKS-A Architecture: Production (vSphere) & Development (Docker) Environments

## High-Level Architecture Diagram

```mermaid
flowchart TD
    subgraph "EKS-A (Production: vSphere Provider)"
        direction TB
        A1[vSphere CSI Storage]
        A2[Infoblox DNS]
        A3[Vault Secrets]
        A4[MetalLB Load Balancer]
        A5[ArgoCD]
        A6[Gatekeeper]
        A7[Metrics Server]
        A8[ExternalDNS - Infoblox]
        A9[External Secrets - Vault]
        A10[User Workloads]
        A1 --> A10
        A2 --> A8
        A3 --> A9
        A4 --> A10
        A5 --> A10
        A6 --> A10
        A7 --> A10
        A8 --> A10
        A9 --> A10
    end

    subgraph "EKS-A (Development: Docker Provider)"
        direction TB
        B1[local-path-provisioner Storage]
        B2[CoreDNS]
        B3[Kubernetes Secrets]
        B4[MetalLB or NodePort/Ingress]
        B5[ArgoCD]
        B6[Gatekeeper]
        B7[Metrics Server]
        B8[ExternalDNS - CoreDNS]
        B9[External Secrets - K8s Secrets]
        B10[User Workloads]
        B1 --> B10
        B2 --> B8
        B3 --> B9
        B4 --> B10
        B5 --> B10
        B6 --> B10
        B7 --> B10
        B8 --> B10
        B9 --> B10
    end

    %% Show that ArgoCD/Helm overlays are shared
    A5 ---|GitOps| B5
```

## Component Mapping Table

| Component/Addon              | EKS-A (vSphere)                | EKS-A (Docker)                | Notes                                      |
|------------------------------|---------------------------------|-------------------------------|--------------------------------------------|
| Storage                      | vSphere CSI                     | local-path-provisioner        | Storage backend differs by provider        |
| DNS                          | Infoblox (ExternalDNS)          | CoreDNS (ExternalDNS)         | ExternalDNS configured per provider        |
| Secrets                      | Vault (External Secrets)        | Kubernetes Secrets            | Use External Secrets for Vault integration |
| Load Balancer                | MetalLB                         | MetalLB or NodePort/Ingress   | MetalLB can be used in both, or NodePort   |
| ArgoCD, Gatekeeper, Metrics  | Same (cloud-agnostic)           | Same                          | No change                                  |
| Cluster Autoscaler           | vSphere/Bare Metal Autoscaler   | N/A or manual scaling         | Optional, depends on infra                 |

## Architecture Summary

- **Both environments use EKS-A** for cluster lifecycle management.
- **Production** runs on vSphere, using vSphere CSI, Infoblox DNS, Vault, and MetalLB.
- **Development** runs on Docker, using local-path-provisioner, CoreDNS, Kubernetes secrets, and MetalLB or NodePort.
- **ArgoCD** is installed via Terraform and manages infrastructure deployment in both environments, with applications managed by ArgoCD.
- **Policy & Metrics:** Gatekeeper and Metrics Server are deployed in both environments.
- **Flexibility:** The architecture supports overlays (via Kustomize/Helm) to adapt manifests for each provider.

## Environment-Specific Overlays

- Use Kustomize or Helm values to manage differences (e.g., storage class, DNS provider, secrets backend).
- ArgoCD applications can reference overlays for prod/dev as needed.

## Infrastructure Management

Infrastructure components are now managed through ArgoCD applications rather than Terraform. This provides better GitOps compliance and allows for easier management of these components.

### Components Managed by ArgoCD

The following infrastructure components are now managed by ArgoCD through Kubernetes manifests:

1. **cert-manager**: Certificate management for TLS certificates
2. **External Secrets Operator**: Secret management integration with external secret stores
3. **local-path-provisioner**: Storage provisioner for development environments
4. **Namespaces**: Required Kubernetes namespaces for the components

These components are deployed through the `apps/infrastructure/` directory which is managed by ArgoCD.

---

**This document is intended for team review and discussion before implementation.**