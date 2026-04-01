# Contributing to OpenCode Systemd

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Code of Conduct

Be respectful, constructive, and inclusive in all interactions.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/grikomsn/opencode-systemd/issues)
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Your environment (OS, OpenCode version, systemd version)
   - Relevant logs or error messages

### Suggesting Features

1. Open an issue describing the feature
2. Explain why it would be useful
3. Provide examples of how it would work

### Pull Requests

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/YOUR_USERNAME/opencode-systemd.git`
3. **Create a branch**: `git checkout -b feature/your-feature-name`
4. **Make your changes**:
   - Follow existing code style
   - Add comments for complex logic
   - Update README.md if needed
5. **Test your changes**:
   - Test on a clean system if possible
   - Test both install and uninstall
   - Verify all commands work
6. **Commit** with clear messages:
   - `feat: add new feature`
   - `fix: resolve bug in install script`
   - `docs: update README`
   - `refactor: improve code structure`
7. **Push** to your fork: `git push origin feature/your-feature-name`
8. **Open a Pull Request**:
   - Link to any related issues
   - Describe what changed and why
   - Reference any testing done

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/opencode-systemd.git
cd opencode-systemd

# Make scripts executable
chmod +x install.sh uninstall.sh wizard.sh

# Test locally
./wizard.sh status
./install.sh --help
```

## Style Guidelines

### Shell Scripts

- Use `#!/usr/bin/env bash` shebang
- Use `set -euo pipefail` for safety
- Quote all variables: `"$VAR"`
- Use lowercase for local variables
- Use UPPERCASE for constants/configuration
- Add comments for non-obvious logic
- Keep functions focused and small

### Commit Messages

- Use present tense: "Add feature" not "Added feature"
- Use imperative mood: "Fix bug" not "Fixes bug"
- Limit first line to 72 characters
- Reference issues when relevant: "Fix #123"

## Testing Checklist

Before submitting a PR, verify:

- [ ] Install works on fresh system
- [ ] Install with `--yes` flag works
- [ ] Custom options (--time, --host, --port) work
- [ ] Uninstall works
- [ ] Wizard all commands work
- [ ] Status shows correct info
- [ ] Logs command works
- [ ] Upgrade command works
- [ ] Service starts correctly
- [ ] Timer triggers correctly
- [ ] No shellcheck warnings (if applicable)

## Questions?

- Open an issue for questions
- Start a discussion in GitHub Discussions

## Recognition

Contributors will be acknowledged in the README and release notes.

Thank you for contributing! 🎉
