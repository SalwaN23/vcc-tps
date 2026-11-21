#!/usr/bin/env bash
# 05_deploy_vm.sh : déployer une instance depuis le template avec un seed cloud-init
# Usage : ./05_deploy_vm.sh app01
set -euo pipefail
source "$(dirname "$0")/env.sh"
N="${1:?nom de la VM, ex. app01}"

WORK="$HOME/tp1-kvm/seed-$N"
INSTANCE_DISK="$IMGDIR/${PREFIX}-$N.qcow2"
SEED="$IMGDIR/${PREFIX}-$N-seed.iso"
PUBKEY="$(cat "$HOME/.ssh/tp1_kvm.pub")"

if [ -e "$INSTANCE_DISK" ]; then
  echo "Le disque $INSTANCE_DISK existe déjà : arrêt."; exit 1
fi

mkdir -p "$WORK"
sudo qemu-img convert -p -f qcow2 -O qcow2 "$TEMPLATE" "$INSTANCE_DISK"
sudo virt-sysprep --enable customize -a "$INSTANCE_DISK" 2>&1 | tail -3

cat > "$WORK/meta-data" <<EOF
instance-id: tp1-${PREFIX}-${N}-v1
local-hostname: $N
EOF

cat > "$WORK/user-data" <<EOF
#cloud-config
preserve_hostname: false
hostname: $N
manage_etc_hosts: true
ssh_deletekeys: true
ssh_genkeytypes: [rsa, ecdsa, ed25519]
ssh_pwauth: false
disable_root: true
users:
  - default
  - name: etudiant
    groups: [adm]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - $PUBKEY
write_files:
  - path: /etc/tp-instance
    permissions: '0644'
    content: |
      Instance : $N
      Reference : ${PREFIX}-template-v1
EOF

genisoimage -output "$WORK/seed.iso" -volid cidata -joliet -rock "$WORK/user-data" "$WORK/meta-data"
sudo cp "$WORK/seed.iso" "$SEED"

sudo virt-install --connect qemu:///system --name "${PREFIX}-$N" \
  --memory 2048 --vcpus 2 --import \
  --disk path="$INSTANCE_DISK",format=qcow2,bus=virtio \
  --disk path="$SEED",device=cdrom,readonly=on \
  --network network=default,model=virtio \
  --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
  --os-variant ubuntu24.04 --graphics vnc,listen=127.0.0.1 --noautoconsole

sudo $V domifaddr "${PREFIX}-$N" --source lease
