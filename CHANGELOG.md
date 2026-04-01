# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-01

### Added
- Initial release
- Interactive CLI wizard (`wizard.sh`)
- One-line installer (`install.sh`)
- One-line uninstaller (`uninstall.sh`)
- Auto-upgrade timer (configurable, default 5 AM)
- Web service with auto-restart on failure
- Service status checking
- Log viewing functionality
- Manual upgrade command
- Support for custom host, port, and upgrade time
- MIT License
- Full documentation and contribution guidelines

### Features
- Install OpenCode web service as systemd user service
- Daily automatic upgrades via systemd timer
- Interactive and CLI modes
- Colorful output with status indicators
- Comprehensive error handling
- Clean uninstall with optional full cleanup

[1.0.0]: https://github.com/grikomsn/opencode-systemd/releases/tag/v1.0.0
