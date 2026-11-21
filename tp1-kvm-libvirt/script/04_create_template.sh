#!/usr/bin/env bash
# 04_create_template.sh : généraliser VM01 et en faire un template
# Usage : ./04_create_template.sh UTILISATEUR_VM01 IP_VM01
set -euo pipefail
source "$(dirname "$0")/env.sh"
GUEST_USER="${1:?utilisateur de VM01}"; GUEST_IP="${2:?IP de VM01}"

if [ -e "$TEMPLATE" ]; then
  echo "Le template $TEMPLATE existe déjà : arrêt pour ne pas l'écraser."; exit 1
fi

echo "== 1. Préparer cloud-init dans VM01, puis l'éteindre =="
ssh -t "$GUEST_USER@$GUEST_IP" 'sudo mkdir -p /etc/cloud/cloud.cfg.d && \
  printf "datasource_list: [ NoCloud, None ]\npreserve_hostname: false\nssh_deletekeys: true\nssh_genkeytypes: [rsa, ecdsa, ed25519]\n" \
  | sudo tee /etc/cloud/cloud.cfg.d/99-z-tp.cfg && \
  sudo rm -f /etc/cloud/cloud-init.disabled && \
  sudo cloud-init clean --logs --seed && sudo poweroff'
until [ "$(sudo $V domstate "$VM")" = "shut off" ]; do sleep 2; done

echo "== 2. Copier le disque puis le généraliser =="
df -h /var/lib/libvirt
sudo qemu-img convert -p -f qcow2 -O qcow2 "$DISK" "$TEMPLATE"
sudo virt-sysprep -a "$TEMPLATE" \
  --operations machine-id,ssh-hostkeys,udev-persistent-net,logfiles,tmp-files,bash-history

echo "== 3. Contrôles =="
sudo qemu-img check -f qcow2 "$TEMPLATE"
sudo qemu-img info "$TEMPLATE" | tee "$P/template-info.txt"
sudo sha256sum "$TEMPLATE" | tee "$P/template.sha256"
sudo virt-cat -a "$TEMPLATE" /etc/cloud/cloud.cfg.d/99-z-tp.cfg
sudo virt-ls -a "$TEMPLATE" /var/lib/cloud/
sudo virt-cat -a "$TEMPLATE" /etc/machine-id | wc -c
