# Boot Time Tuning: devtop

Boot optimization for a bare-metal Fedora/RHEL-based desktop booting from local NVMe only.

> Note: the system was first described as Linux Mint, but `gdm`, `firewalld`, `chronyd`, SELinux and `dbus-broker` show it's Fedora/RHEL-based. Check with `cat /etc/os-release`.

## Results

| Stage      | Before  | After   |
|------------|---------|---------|
| Userspace  | 13.6s   | 6.0s    |
| Total      | ~30s    | 22.8s   |

Remaining time is mostly firmware (7.7s) and loader (4.0s). See steps 6 and 7.

---

## Quick start

```bash
sudo ./boot-tune.sh            # services only
sudo ./boot-tune.sh --grub     # services + GRUB timeout to 0
sudo reboot
```

---

## 1. Measure baseline

```bash
#!/usr/bin/env bash
# 2026-10-04
# Record boot times before changing anything
systemd-analyze                     # total time per stage
systemd-analyze blame | head -15    # slowest units (duration, not blocking)
systemd-analyze critical-chain      # what actually delays boot
systemctl list-unit-files --type=service --state=enabled > services-before.txt
```

Note: `critical-chain` only reports the **last boot**. Reboot before re-checking.

---

## 2. Disable unused services

```bash
#!/usr/bin/env bash
# 2026-10-04
# Enterprise storage, perf logging, crash dumps, modems: not needed on this desktop
sudo systemctl disable --now \
  iscsi-onboot iscsi-starter multipathd nvmefc-boot-connections \
  libstoragemgmt mdmonitor \
  pmcd pmie pmlogger sysstat \
  kdump ModemManager atd \
  NetworkManager-wait-online
```

| Service | Why it's safe to disable |
|---|---|
| `iscsi-*`, `multipathd`, `nvmefc-boot-connections` | Network/SAN storage only |
| `libstoragemgmt`, `mdmonitor` | Enterprise storage, software RAID |
| `pmcd`, `pmie`, `pmlogger`, `sysstat` | Performance logging |
| `kdump` | Crash dumps; frees reserved RAM |
| `ModemManager` | Cellular modems only |
| `atd` | One-off scheduled jobs, rarely used |
| `NetworkManager-wait-online` | Blocks boot waiting for network |

---

## 3. Docker on demand

```bash
#!/usr/bin/env bash
# 2026-10-04
# Start Docker on first use instead of at boot
sudo systemctl disable docker.service
sudo systemctl enable docker.socket
```

---

## 4. Remove network waits (biggest win: ~8s)

```bash
#!/usr/bin/env bash
# 2026-10-04
# unbound-anchor: DNSSEC key refresh, took 11.7s (only needed with unbound resolver)
# nfs-client: held remote-fs.target ~8s with no remote mounts
sudo systemctl disable --now unbound-anchor.timer nfs-client.target
```

---

## 5. Remove VM guest agents (bare metal only)

The `NTC0702` TPM device shows this is physical hardware.

```bash
#!/usr/bin/env bash
# 2026-10-04
# Only disable if not a VM
if [[ "$(systemd-detect-virt || true)" == "none" ]]; then
  sudo systemctl disable --now qemu-guest-agent vmtoolsd vgauthd
fi
```

Optional, if unused:
- `sssd`: LDAP/AD logins
- `virtqemud`: running VMs on this host
- `switcheroo-control`: dual-GPU laptops

---

## 6. Shorten GRUB wait (loader: 4.0s)

```bash
#!/usr/bin/env bash
# 2026-10-04
# Skip GRUB menu; hold Shift or press Esc at boot to show it
sudo cp /etc/default/grub /etc/default/grub.bak
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

Optional: drop the boot splash (`plymouth-quit-wait`, ~3s). Gains are often small.

```bash
#!/usr/bin/env bash
# 2026-10-04
sudo grubby --update-kernel=ALL --remove-args="rhgb"   # undo: --args="rhgb"
```

---

## 7. Firmware (7.7s): manual BIOS/UEFI

- Enable Fast Boot
- Disable network/PXE boot
- Remove unused boot devices
- Disable unused controllers (extra SATA, serial ports)

---

## 8. Verify

```bash
#!/usr/bin/env bash
# 2026-10-04
# Run after reboot
systemd-analyze
systemd-analyze critical-chain
```

---

## Rollback

```bash
#!/usr/bin/env bash
# 2026-10-04
# Re-enable any unit
sudo systemctl enable --now <unit>

# Restore GRUB
sudo cp /etc/default/grub.bak /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# Docker back to boot-time start
sudo systemctl disable docker.socket && sudo systemctl enable docker.service
```
