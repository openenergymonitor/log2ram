# Log2Ram

Keeps `/var/log` in RAM to reduce writes to the SD card, and copies it to disk every hour and at shutdown.

This is the [OpenEnergyMonitor](https://openenergymonitor.org) fork of [azlux/log2ram](https://github.com/azlux/log2ram), used on the emonSD image for the emonPi and emonBase. If you are not using emonSD, the upstream project may suit you better: it is actively developed, and this fork split from it in 2018.

Logs written since the last copy to disk are lost if power is removed without a clean shutdown.

## Differences from upstream

- Copies to disk with `rsync --inplace --no-whole-file`, which rewrites only the parts of a log that changed.
- The copy of the logs on disk is in `/var/log.bak`.
- Rotated logs are moved out of RAM to `/var/log.old`, and are linked from `/var/log/rotated_logs`.
- The installer deletes `/var/log/journal`, so `journald` does not keep its logs on the SD card.

## Install

On emonSD, this is already installed. [EmonScripts](https://github.com/openenergymonitor/EmonScripts) installs it as part of the image build.

To install it yourself:

```shell
git clone https://github.com/openenergymonitor/log2ram.git
cd log2ram
sudo ./install.sh
sudo reboot
```

`rsync` needs to be installed first, unless you set `USE_RSYNC=false` in `log2ram.conf`. Reboot before installing anything else.

## Upgrade

The emonSD update does not upgrade log2ram, so a device keeps the version from its image. To upgrade by hand:

```shell
sudo systemctl stop log2ram
git pull
sudo ./install.sh
sudo reboot
```

Installing **deletes the rotated logs in `/var/log.old` and replaces `/etc/log2ram.conf`**, so note any settings you have changed first.

## Where the logs are

| Location | Stored on | Contents |
|---|---|---|
| `/var/log` | RAM | The current logs |
| `/var/log.bak` | Disk | The copy made every hour and at shutdown, which is loaded back into RAM at boot |
| `/var/log.old` | Disk | Rotated logs, also available at `/var/log/rotated_logs` |

## Configuration

Settings are in `/etc/log2ram.conf`. Restart the device after changing them.

| Setting | Default | Description |
|---|---|---|
| `SIZE` | `50M` | Space for `/var/log` in RAM |
| `USE_RSYNC` | `true` | Copy with `rsync`. If `false`, `cp` is used instead |
| `MAIL` | `true` | Send a system mail if the logs do not fit in `SIZE`. This needs the `mail` command, which may not be installed |

## Hourly copy and log rotation

The installer adds `/etc/cron.hourly/log2ram`, which copies the logs to disk.

emonSD replaces that file with its own from EmonScripts, which also runs `logrotate` every hour. Doing so stops the logs filling the space in RAM between daily rotations.

## Is it working?

```shell
df -h /var/log
systemctl status log2ram
```

`df` should show `log2ram` as the filesystem for `/var/log`. Log2Ram's own log is `/var/log/log2ram.log`.

## If the logs do not fit in RAM

If the logs on disk are larger than `SIZE` at boot, log2ram does not start, and **logs are then written straight to the SD card**. `df -h /var/log` will not show `log2ram`, and `journalctl -u log2ram` shows `RAM disk too small`.

To fix this, find what is using the space, then remove it or increase `SIZE`, and reboot:

```shell
sudo du -xh /var/log | sort -h | tail
```

## Uninstall

```shell
sudo /usr/local/bin/uninstall-log2ram.sh
```

This also deletes `/var/log.bak` and `/var/log.old`.

## License

MIT, see [LICENSE](LICENSE). Based on the work of [azlux](https://github.com/azlux/log2ram) and [A transient /var/log](https://www.debian-administration.org/article/661/A_transient_/var/log).
