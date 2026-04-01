# OpenCode Systemd

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/grikomsn/opencode-systemd/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![OpenCode](https://img.shields.io/badge/OpenCode-Compatible-green.svg)](https://opencode.ai)

A systemd service manager for [OpenCode](https://opencode.ai) with automatic daily upgrades.

## Features

- 🚀 **One-line install** - Get OpenCode running as a systemd service in seconds
- 🔄 **Auto-upgrades** - Daily automatic updates via systemd timers
- 🖥️ **Web UI** - Runs OpenCode web interface on localhost
- ⚙️ **Configurable** - Customize host, port, and upgrade schedule
- 🔧 **CLI Wizard** - Interactive management tool
- 📝 **OSS** - MIT licensed, contributions welcome

## Quick Start

### One-line Install

```bash
curl -fsSL https://raw.githubusercontent.com/grikomsn/opencode-systemd/main/install.sh | bash
```

### Manual Install

```bash
git clone https://github.com/grikomsn/opencode-systemd.git
cd opencode-systemd
./install.sh
```

After installation, access OpenCode at: **http://127.0.0.1:4096**

## Usage

### CLI Commands

Once installed, use the `opencode-systemd` command:

```bash
# Interactive wizard
opencode-systemd

# Check status
opencode-systemd status

# Run manual upgrade
opencode-systemd upgrade

# Update configuration
opencode-systemd update

# View logs
opencode-systemd logs

# Show help
opencode-systemd --help
```

### Systemd Commands

Standard systemd commands also work:

```bash
# Service status
systemctl --user status opencode-web.service

# Start/stop/restart
systemctl --user start opencode-web.service
systemctl --user stop opencode-web.service
systemctl --user restart opencode-web.service

# View timer
systemctl --user list-timers opencode-upgrade.timer

# View logs
journalctl --user -u opencode-web.service -f
```

## Configuration

### Install Options

```bash
# Install without prompts
curl -fsSL .../install.sh | bash -s -- --yes

# Custom upgrade time (3 AM)
curl -fsSL .../install.sh | bash -s -- --time 03:00:00

# Custom host and port
curl -fsSL .../install.sh | bash -s -- --host 0.0.0.0 --port 8080

# All options combined
curl -fsSL .../install.sh | bash -s -- --yes --time 03:00:00 --host 0.0.0.0 --port 8080
```

### Service Files

The installer creates three systemd units:

| Service | Type | Description |
|---------|------|-------------|
| `opencode-web.service` | Simple | Main web service with auto-upgrade on start |
| `opencode-upgrade.service` | Oneshot | Runs `opencode upgrade` and restarts web |
| `opencode-upgrade.timer` | Timer | Triggers upgrade daily at configured time |

Files are located in `~/.config/systemd/user/`.

## Uninstall

### One-line Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/grikomsn/opencode-systemd/main/uninstall.sh | bash
```

### Options

```bash
# Uninstall without prompts
curl -fsSL .../uninstall.sh | bash -s -- --yes

# Full cleanup (remove wizard too)
curl -fsSL .../uninstall.sh | bash -s -- --full --yes
```

## Requirements

- [OpenCode](https://opencode.ai) installed
- systemd (available on most modern Linux distributions)
- bash 4.0+
- curl or wget

## File Structure

```
opencode-systemd/
├── install.sh          # One-line installer
├── uninstall.sh        # Uninstaller script
├── wizard.sh           # Main CLI wizard
├── README.md           # This file
├── LICENSE             # MIT License
├── CONTRIBUTING.md     # Contribution guidelines
└── .gitignore          # Git ignore rules
```

## How It Works

1. **Install**: Downloads wizard, creates systemd service files, enables and starts services
2. **Auto-upgrade**: Timer triggers daily at configured time (default: 5 AM)
3. **Upgrade process**:
   - Timer activates `opencode-upgrade.service`
   - Service runs `opencode upgrade`
   - On success, web service is restarted
4. **Web service**: Runs `opencode web` on configured host:port

## Troubleshooting

### Service fails to start

```bash
# Check status and recent logs
opencode-systemd status
opencode-systemd logs

# Or manually
systemctl --user status opencode-web.service
journalctl --user -u opencode-web.service -n 50
```

### Upgrade not working

```bash
# Check timer status
systemctl --user list-timers

# Check if upgrade service ran
journalctl --user -u opencode-upgrade.service -n 20
```

### Reset everything

```bash
# Uninstall and reinstall
curl -fsSL .../uninstall.sh | bash -s -- --full --yes
curl -fsSL .../install.sh | bash
```

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) file.

## Credits

Created by [grikomsn](https://github.com/grikomsn) for the OpenCode community.

---

**Note**: This is an unofficial community tool. Not affiliated with OpenCode.ai.
