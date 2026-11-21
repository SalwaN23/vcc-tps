#!/usr/bin/env bash
# 01_install_kvm.sh : vérifier la virtualisation et installer KVM/libvirt
set -euo pipefail

echo "== Support matériel =="
lscpu | grep -i virtualization || true
grep -Ec '(vmx|svm)' /proc/cpuinfo
lsmod | grep kvm || true
ls -l /dev/kvm

echo "== Installation des paquets =="
sudo apt update
sudo apt install -y qemu-system-x86 libvirt-daemon-system libvirt-clients \
  virtinst virt-manager virt-viewer qemu-utils libguestfs-tools genisoimage

echo "== Vérification =="
sudo virsh -c qemu:///system list --all
