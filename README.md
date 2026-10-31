# Virtualization & Cloud Computing: Lab Work

**Master Big Data & Cloud Computing (BD2C)**, Faculté des Sciences Aïn Chock, Université Hassan II Casablanca
**Academic year:** 2026/2027
**Author:** Salwa Naciri

## About this repository

This repository gathers my lab reports for the *Virtualization & Cloud Computing* module. Each lab is documented with commands, screenshots, observed results and answers to the questions.

## Labs

| Lab | Topic | Folder | Status |
|-----|-------|--------|--------|
| TP1 | **Virtualization with KVM/QEMU and libvirt**: creating a VM from an ISO, full clone, OS image capture and re-import, generalized template, deployment of two instances (app01/app02), RAW vs QCOW2, clone/template/image decision cases | `tp1-kvm-libvirt/` | In progress |
| TP2 | **VM customization and automation with cloud-init**: NoCloud seed ISO, users and SSH keys, network configuration, packages and files, reusable profiles, Jinja2 generation from a YAML inventory, multi-VM mini-project (web, database, admin) | `tp2-cloud-init/` | Not started |

## Skills covered

**TP1**
- Checking KVM support and managing VMs with `virsh`, `virt-install`, `virt-clone`
- Identifying duplicated identities after cloning (MAC, UUID, hostname, machine-id, SSH host keys)
- Disk images and conversion with `qemu-img` (RAW / QCOW2, checksums, re-import)
- Generalizing a template with `virt-sysprep`

**TP2**
- Writing `user-data`, `meta-data` and `network-config` for the NoCloud datasource
- Automating users, SSH access, network, packages and services at first boot
- Generating configurations for several VMs with Python, Jinja2 and a YAML inventory
- Diagnosing cloud-init (`cloud-init status`, `analyze`, logs, `schema`)

## Environment

- Ubuntu host running in VMware, with KVM/QEMU/libvirt (NAT network `default`)
- Guests: Ubuntu images compatible with cloud-init

> Large files (QCOW2/ISO images) and secrets (private SSH keys) are intentionally not published.
