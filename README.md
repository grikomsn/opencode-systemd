# OpenCode Systemd

Systemd service files and installer for [OpenCode](https://opencode.ai).

Runs `opencode web` as a user service with daily auto-upgrades via systemd timer.

## Install

```bash
curl -fsSL https://ocsd.nbr.st/install.sh | bash
```

This creates:
- `~/.config/systemd/user/opencode-web.service` — web UI with auto-upgrade on start
- `~/.config/systemd/user/opencode-upgrade.timer` — daily upgrade at 05:00
- `~/.opencode/bin/opencode-systemd-wizard` — management CLI

## Usage

```bash
opencode-systemd status    # check services
opencode-systemd upgrade   # manual upgrade + restart
opencode-systemd logs      # view logs
opencode-systemd --help    # all commands
```

Or use systemd directly:

```bash
systemctl --user {start,stop,restart} opencode-web.service
systemctl --user list-timers opencode-upgrade.timer
journalctl --user -u opencode-web.service -f
```

## Uninstall

```bash
curl -fsSL https://ocsd.nbr.st/uninstall.sh | bash
```

## Configuration

Install with custom settings:

```bash
curl -fsSL https://ocsd.nbr.st/install.sh | bash -s -- \
  --time 03:00:00 --host 0.0.0.0 --port 8080
```

Or edit service files directly in `~/.config/systemd/user/`.

---

MIT License · https://ocsd.nbr.st · [View pi thread](https://pi.dev/session/#dd89599ff8d6a9be8eb59161772d5ec6)
