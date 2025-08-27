# README.md

# EKS-A (Tinkerbell) on GCP VMs — Ansible Automation

This repository contains an Ansible-based workflow to prepare, collect inventory, and render EKS Anywhere (Tinkerbell) YAMLs for a **bare-metal** installation on VMs hosted in Google Cloud (GCP).

> **Goal:** gather MACs and network facts from your VMs, produce `hardware.csv` and required EKS-A YAMLs (`Cluster`, `TinkerbellDatacenterConfig`, `TinkerbellMachineConfig`, `TinkerbellTemplateConfig`), and place them in `./build/` for `eksctl anywhere create cluster ...`.

---

## Project layout

```
eks-a-ansible/
├── inventory.ini            # Ansible inventory: admin, cp, workers
├── group_vars/
│   └── all.yml              # Global variables (cluster_name, endpoints, etc.)
├── templates/
│   ├── cluster.yaml.j2
│   ├── datacenter.yaml.j2
│   ├── machine_cp.yaml.j2
│   ├── machine_wk.yaml.j2
│   ├── templateconfig.yaml.j2
│   └── hardware.csv.j2
├── playbooks/
│   └── render.yml
└── build/                   # Output (generated) files after running playbook
```

---

## Prerequisites

1. **Ansible** (>=2.10 recommended) on the host where you will run the playbook.
2. SSH key-based access from the Ansible host to all `cp` and `worker` VMs (the playbook gathers facts via SSH).
3. `eksctl-anywhere` and Docker installed on the **admin** machine (the machine that will run `eksctl anywhere create cluster ...`).
4. The VMs should use an Ubuntu variant with Python available (Ansible uses Python remote facts). Typical images like `ubuntu-20.04` work fine.
5. Ensure internal IPs you plan to use are reserved / static on GCP (recommended) so `hardware.csv` IPs remain stable.
6. If you want the playbook to reserve IPs on GCP automatically, install and configure `gcloud` and provide the necessary IAM permissions (this is optional and not included by default).

---

## Quick start — render everything

1. Edit `inventory.ini` to match your VMs (admin, cp, workers). Example format:

```ini
[admin]
admin ansible_host=203.0.113.10 ansible_user=ubuntu

[cp]
cp1 ansible_host=10.2.0.11 ansible_user=ubuntu
cp2 ansible_host=10.2.0.12 ansible_user=ubuntu
cp3 ansible_host=10.2.0.13 ansible_user=ubuntu

[workers]
wk1 ansible_host=10.2.0.21 ansible_user=ubuntu
wk2 ansible_host=10.2.0.22 ansible_user=ubuntu

[all:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

2. Update `group_vars/all.yml` with your cluster-specific variables: `cluster_name`, `control_plane_endpoint`, `tinkerbell_ip`, `ssh_pub_key`, `os_image_url` (important), `ansible_user`, etc.

3. From `playbooks/` run:

```bash
ansible-playbook -i ../inventory.ini render.yml
```

This will:

* SSH into `cp` and `workers` to gather facts (notably `ansible_default_ipv4.macaddress`).
* Render the Jinja2 templates locally into `./build/` (create `cluster.yaml`, `datacenter.yaml`, `machine_cp.yaml`, `machine_wk.yaml`, `templateconfig.yaml`, and `hardware.csv`).

4. Inspect `build/hardware.csv` and `build/cluster.yaml` — **verify** MACs and IPs are correct.

5. Copy `build/` to the admin machine (if you did not run the playbook on the admin machine). Example using `scp` or `rsync`:

```bash
rsync -av build/ ubuntu@203.0.113.10:~/eks-a-build/
# or
scp build/* ubuntu@203.0.113.10:~/eks-a-build/
```

6. On the admin machine run:

```bash
eksctl anywhere create cluster -f ~/eks-a-build/cluster.yaml --hardware-csv ~/eks-a-build/hardware.csv
```

---

## What the rendered `build/` contains

* `cluster.yaml` — The `Cluster` object with controlPlaneConfiguration and workerNodeGroupConfigurations.
* `datacenter.yaml` — `TinkerbellDatacenterConfig` with `tinkerbellIP` and other datacenter-specific settings.
* `machine_cp.yaml` / `machine_wk.yaml` — `TinkerbellMachineConfig` objects for control plane and workers. The `hardwareSelector` matches labels in `hardware.csv`.
* `templateconfig.yaml` — `TinkerbellTemplateConfig` containing `osImageURL` (replace by a valid image if placeholder present).
* `hardware.csv` — one row per VM with MACs and IP addresses. This is required by Tinkerbell for PXE identification.

---

## How MAC collection works (Ansible details)

* The playbook gathers facts from `cp` and `workers` using `gather_facts: yes`.
* It uses `ansible_default_ipv4.macaddress` and `ansible_default_ipv4.address` to populate `mac` and `ip_address` columns in `hardware.csv`.
* If a host does not present `ansible_default_ipv4` facts, the playbook will `assert` and fail so you can fix network configuration before proceeding.

### Ad-hoc MAC check commands

Get MACs quickly without running the full render flow:

```bash
ansible -i inventory.ini cp:workers -m setup -a "filter=ansible_default_ipv4" -u ubuntu
```

or run a raw command to list NICs:

```bash
ansible -i inventory.ini cp:workers -a "ip -o link show" -u ubuntu
```

---

## Important variables to edit in `group_vars/all.yml`

* `cluster_name` — cluster metadata name
* `kubernetes_version` — e.g. `1.33`
* `control_plane_endpoint` — IP that will act as cluster endpoint (reserved/static)
* `tinkerbell_ip` — the IP for Tinkerbell API/Boots on the network
* `ssh_pub_key` — the public key to install into machine YAMLs
* `os_image_url` — **replace** the placeholder with the actual OS image URL
* `ansible_user` — the user that exists on the VM (e.g., `ubuntu`)
* `cp_label_key` / `cp_label_value` and `wk_label_key` / `wk_label_value` — labels used in `hardware.csv` and `TinkerbellMachineConfig.hardwareSelector`
* `build_dir` — output directory (default `./build`)

---

## Optional: Reserve internal IPs on GCP (example)

> *This is optional. It requires `gcloud` and proper IAM permissions.*

Reserve an internal static IP in the VPC (example):

```bash
gcloud compute addresses create mgmt-cp-endpoint --region=us-central1 --subnet=my-subnet --addresses=10.2.0.9
```

Reserve the Tinkerbell IP similarly (use your network/subnet). Alternatively, assign static internal IPs during VM creation in the GCP console or with `gcloud compute instances create` using `--private-network-ip`.

---

## Troubleshooting & common gotchas

* **No MACs in `hardware.csv`:** ensure the host is reachable by SSH and `ansible_default_ipv4` exists. If your image uses `netplan` but no IPv4 is configured, Ansible may not collect `ansible_default_ipv4`.

* **PXE/DHCP fails on GCP:** since GCP controls the virtual networking, Boots (Tinkerbell DHCP) may not see PXE requests. Use static IPs and ensure the admin (Tinkerbell) and target nodes are in the same L2 broadcast domain if you want PXE to work, or configure DHCP in the cloud to point to iPXE (advanced). In most cases for GCP VMs you will use image push (`image2disk`) or ensure Boots runs with host network privileges in the same subnet.

* **No BMC/IPMI:** GCP VMs don't have IPMI. Leave BMC fields empty in `hardware.csv`. Manual reboots are required for power-cycle operations, or implement cloud-provider hooks to reboot VMs via `gcloud` using a custom workflow.

* **`osImageURL` invalid or unreachable:** ensure the admin node can reach the URL and that the image format is supported by EKS-A/Tinkerbell.

* **User mismatch:** if your VM user is `ubuntu` but your template uses `ec2-user`, change the `ansible_user` variable.

---

## Post-deploy checks

On the admin/bootstrap machine during provisioning you can monitor:

```bash
docker ps   # show Tinkerbell containers (boots, tink, hegel, etc.)
docker logs boots -f
kubectl --kubeconfig ./eks-a-bootstrap-kubeconfig get pods -A
```

After `eksctl anywhere` finishes, use the provided kubeconfig to verify cluster nodes:

```bash
kubectl get nodes
kubectl get pods -A
```

---

## Advanced notes & next steps

* You can extend the playbook to **call GCP APIs** (via `gcloud` or the `google.cloud` Ansible collection) to: reserve internal IPs, tag instances, or perform reboots. This requires IAM service account credentials and is optional.
* If Tinkerbell PXE is unreliable on GCP, consider using `image2disk` flows or pre-baking images that match EKS-A expected layout and use `eksctl anywhere` to register them, but that is an advanced flow.
* Consider adding a `verify.yml` playbook that runs sanity checks (validate `hardware.csv` entries, ping endpoints, validate port 6443 reachability, ensure `containerd` installed, etc.) before running `eksctl anywhere create`.

---

## References

* EKS Anywhere bare-metal / Tinkerbell documentation (official AWS docs) — consult for latest schema and recommended OS images.
* Tinkerbell project docs for PXE and DHCP behavior.

---

## Contact / support

If you want, I can:

* add an Ansible task to call `gcloud` to reserve IPs and annotate the inventory,
* add a `verify.yml` playbook for pre-deploy checks,
* or produce a `Makefile` to orchestrate render/copy/deploy steps.

Choose one and I’ll add it to the repo.
