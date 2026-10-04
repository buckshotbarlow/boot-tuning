#!/usr/bin/env bash
# 2026-10-04
# boot-tune.sh: speed up boot on a bare-metal Fedora/RHEL desktop (local NVMe only)
# Usage: sudo ./boot-tune.sh [--grub]
set -euo pipefail

UNUSED=(
  iscsi-onboot iscsi-starter multipathd nvmefc-boot-connections
  libstoragemgmt mdmonitor
  pmcd pmie pmlogger sysstat
  kdump ModemManager atd
  NetworkManager-wait-online
)
NETWORK_WAITS=(unbound-anchor.timer nfs-client.target)
GUEST_AGENTS=(qemu-guest-agent vmtoolsd vgauthd)

# Exit unless running as root
require_root() {
  [[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
}

# Disable and stop each unit; skip ones that don't exist
disable_units() {
  for unit in "$@"; do
    if systemctl disable --now "$unit" &>/dev/null; then
      echo "disabled: $unit"
    else
      echo "skipped:  $unit"
    fi
  done
}

# Start Docker on first use instead of at boot
docker_on_demand() {
  systemctl list-unit-files docker.socket &>/dev/null || return 0
  systemctl disable docker.service &>/dev/null || true
  systemctl enable docker.socket &>/dev/null && echo "docker: socket activation"
}

# Remove VM guest agents on physical hardware only
remove_guest_agents() {
  local virt
  virt=$(systemd-detect-virt || true)
  if [[ $virt == "none" ]]; then
    disable_units "${GUEST_AGENTS[@]}"
  else
    echo "VM detected ($virt): keeping guest agents"
  fi
}

# Set GRUB menu timeout to 0 (backup kept at /etc/default/grub.bak)
grub_no_wait() {
  cp /etc/default/grub /etc/default/grub.bak
  sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
  grub2-mkconfig -o /boot/grub2/grub.cfg &>/dev/null
  echo "grub: timeout 0 (hold Shift/Esc for menu)"
}

main() {
  require_root
  echo "== Unused services =="
  disable_units "${UNUSED[@]}"
  echo "== Network waits =="
  disable_units "${NETWORK_WAITS[@]}"
  echo "== Docker =="
  docker_on_demand
  echo "== Guest agents =="
  remove_guest_agents
  if [[ ${1:-} == "--grub" ]]; then
    echo "== GRUB =="
    grub_no_wait
  fi
  echo "Done. Reboot, then run: systemd-analyze critical-chain"
}

main "$@"
