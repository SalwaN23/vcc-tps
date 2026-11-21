#!/usr/bin/env bash
# 02_create_vm.sh : créer VM01 depuis l'ISO Ubuntu (équivalent en ligne de commande)
set -euo pipefail
source "$(dirname "$0")/env.sh"

ISO="${ISO:-$HOME/tp1-kvm/iso/ubuntu-24.04-live-server-amd64.iso}"   # adapter au vrai nom
DISK_SIZE="${DISK_SIZE:-20}"                                          # en Go, adapter

if sudo $V dominfo "$VM" >/dev/null 2>&1; then
  echo "La VM $VM existe déjà : rien à faire."; exit 0
fi

sudo qemu-img create -f qcow2 "$DISK" "${DISK_SIZE}G"
sudo virt-install --connect qemu:///system \
  --name "$VM" --memory 2048 --vcpus 2 \
  --disk path="$DISK",format=qcow2,bus=virtio \
  --cdrom "$ISO" \
  --network network=default,model=virtio \
  --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
  --os-variant "$OSVAR" --graphics vnc,listen=127.0.0.1 --noautoconsole

sudo $V list --all
