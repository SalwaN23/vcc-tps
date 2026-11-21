#!/usr/bin/env bash
# 03_clone_vm.sh : cloner VM01 en VM02 (la VM source doit être éteinte)
set -euo pipefail
source "$(dirname "$0")/env.sh"

if [ "$(sudo $V domstate "$VM")" != "shut off" ]; then
  sudo $V shutdown "$VM"
  until [ "$(sudo $V domstate "$VM")" = "shut off" ]; do sleep 2; done
fi

sudo virt-clone --original "$VM" --name "$CLONE" --auto-clone
sudo $V list --all
