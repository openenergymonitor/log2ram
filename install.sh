#!/usr/bin/env sh

# Under latest RPi-OS the folder /var/log/journal is created so journald reverts to persistent journal files
# Delete this folder and restart service
if [ -d /var/log/journal ]; then
  echo "/var/log/journal present - remove for volatile journal files"
  sudo rm -rf /var/log/journal
  sudo systemctl restart systemd-journald
fi

# Compare the state: with SYSTEMD_OFFLINE=1 (image builds) systemctl ignores
# is-active, printing nothing and exiting 0
[ "$(systemctl is-active log2ram 2>/dev/null)" = "active" ] && { echo "ERROR: log2ram service is still running. Please run \"sudo service log2ram stop\" to stop it."; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "You need to be ROOT (sudo can be used)"; exit 1; }

# log2ram
mkdir -p /usr/local/bin/
install -m 644 log2ram.service /etc/systemd/system/log2ram.service
install -m 755 log2ram /usr/local/bin/log2ram
install -m 644 log2ram.conf /etc/log2ram.conf
install -m 644 uninstall.sh /usr/local/bin/uninstall-log2ram.sh
systemctl enable log2ram

# cron
install -m 755 log2ram.hourly /etc/cron.hourly/log2ram
install -m 644 log2ram.logrotate /etc/logrotate.d/log2ram
install -m 644 log2ram.00_olddir /etc/logrotate.d/00_olddir

# Remove a previous log2ram version
  rm -rf /var/log.hdd
  rm -rf /var/hdd.log

# Make sure we start clean
rm -rf /var/log.bak
rm -rf /var/log.old

echo "##### Reboot to activate log2ram #####"
