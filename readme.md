(root) devtop:/home/barlow
502 -> systemd-analyze 
Startup finished in 7.709s (firmware) + 4.005s (loader) + 820ms (kernel) + 4.178s (initrd) + 6.064s (userspace) = 22.779s 
graphical.target reached after 6.032s in userspace.
runnin linux mint, here's my services. which are needed and which can be disabled?
530 -> systemctl list-unit-files --type=service --state=enabled 
UNIT FILE                          STATE   PRESET   
accounts-daemon.service            enabled enabled  
atd.service                        enabled enabled  
audit-rules.service                enabled enabled  
auditd.service                     enabled enabled  
chronyd.service                    enabled enabled  
crond.service                      enabled enabled  
dbus-broker.service                enabled enabled  
docker.service                     enabled disabled 
fips-crypto-policy-overlay.service enabled enabled  
firewalld.service                  enabled enabled  
gdm.service                        enabled enabled  
getty@.service                     enabled enabled  
irqbalance.service                 enabled enabled  
iscsi-onboot.service               enabled enabled  
iscsi-starter.service              enabled enabled  
kdump.service                      enabled enabled  
libstoragemgmt.service             enabled enabled  
lm_sensors.service                 enabled enabled  
lvm2-monitor.service               enabled enabled  
mcelog.service                     enabled enabled  
mdmonitor.service                  enabled enabled  
ModemManager.service               enabled enabled  
multipathd.service                 enabled enabled  
NetworkManager-dispatcher.service  enabled enabled  
NetworkManager-wait-online.service enabled enabled  
NetworkManager.service             enabled enabled  
nvmefc-boot-connections.service    enabled enabled  
pmcd.service                       enabled enabled  
pmie.service                       enabled enabled  
pmlogger.service                   enabled enabled  
qemu-guest-agent.service           enabled enabled  
rsyslog.service                    enabled enabled  
rtkit-daemon.service               enabled enabled  
selinux-autorelabel-mark.service   enabled enabled  
smartd.service                     enabled enabled  
sshd.service                       enabled enabled  
sssd.service                       enabled enabled  
switcheroo-control.service         enabled enabled  
sysstat.service                    enabled enabled  
systemd-confext.service            enabled enabled  
systemd-network-generator.service  enabled enabled  
systemd-pstore.service             enabled enabled  
systemd-sysext.service             enabled enabled  
tailscaled.service                 enabled disabled 
thermald.service                   enabled enabled  
tuned-ppd.service                  enabled enabled  
tuned.service                      enabled enabled  
udisks2.service                    enabled enabled  
upower.service                     enabled enabled  
vgauthd.service                    enabled disabled 
virtqemud.service                  enabled enabled  
vmtoolsd.service                   enabled enabled

sudo systemctl disable --now iscsi-onboot iscsi-starter multipathd nvmefc-boot-connections libstoragemgmt mdmonitor pmcd pmie pmlogger sysstat kdump ModemManager atd NetworkManager-wait-online
sudo systemctl disable docker.service && sudo systemctl enable docker.socket
sudo systemctl disable --now unbound-anchor.timer
sudo systemctl disable --now unbound-anchor.timer nfs-client.target
