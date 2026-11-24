#!/usr/bin/env bash
# deploy.sh : lancer une VM de l'inventaire a partir du template et de son seed
# Usage : ./scripts/deploy.sh vm_web
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMGDIR=/var/lib/libvirt/images
TEMPLATE="$IMGDIR/ubuntu-template-v1.qcow2"
TARGET="${1:?usage: ./scripts/deploy.sh vm_web ou vm_db ou vm_admin}"

INFO="$(python3 - "$ROOT" "$TARGET" <<'PY'
import sys, yaml
root, name = sys.argv[1], sys.argv[2]
inv = yaml.safe_load(open(root + "/inventaire/vms.yaml"))
for vm in inv["vms"]:
    if vm["name"] == name:
        print(vm["hostname"], vm["cpu"], vm["ram"])
        sys.exit(0)
sys.exit("VM inconnue dans l inventaire : " + name)
PY
)"
read -r HOST CPU RAM <<< "$INFO"

VM="bd2c-$HOST"
DISK="$IMGDIR/$VM.qcow2"
SEED="$IMGDIR/bd2c-seed-$HOST.iso"

if sudo virsh -c qemu:///system dominfo "$VM" >/dev/null 2>&1; then
  echo "La VM $VM existe deja : arret."; exit 1
fi
if [ -e "$DISK" ]; then
  echo "Le disque $DISK existe deja : arret."; exit 1
fi

echo "== Deploiement de $VM : $CPU vCPU, $RAM Mo =="
sudo cp "$TEMPLATE" "$DISK"
sudo cp "$ROOT/output/$TARGET/seed.iso" "$SEED"
sudo qemu-img check -f qcow2 "$DISK"

sudo virt-install --connect qemu:///system \
  --name "$VM" --memory "$RAM" --vcpus "$CPU" --import \
  --disk path="$DISK",format=qcow2,bus=virtio \
  --disk path="$SEED",device=cdrom,readonly=on \
  --network network=default,model=virtio \
  --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
  --os-variant ubuntu24.04 --graphics vnc,listen=127.0.0.1 --noautoconsole

echo "== Attente de l adresse IP =="
for i in $(seq 1 24); do
  sleep 5
  ADDR="$(sudo virsh -c qemu:///system domifaddr "$VM" --source lease | awk '/ipv4/ {print $4}')"
  [ -n "$ADDR" ] && break
done
echo "$VM : ${ADDR:-adresse non obtenue}"
