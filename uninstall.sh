#!/usr/bin/env bash
#
# OpenCode Systemd - Uninstaller
# Quick uninstall script for opencode-systemd services
#
# Usage: curl -fsSL https://raw.githubusercontent.com/grikomsn/opencode-systemd/main/uninstall.sh | bash
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Paths
USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
OPENCODE_BIN_DIR="$HOME/.opencode/bin"

# Service files
WEB_SERVICE="$USER_SYSTEMD_DIR/opencode-web.service"
UPGRADE_SERVICE="$USER_SYSTEMD_DIR/opencode-upgrade.service"
UPGRADE_TIMER="$USER_SYSTEMD_DIR/opencode-upgrade.timer"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}→${NC} $1"
}

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
   ____                      _____          _           _
  / __ \                    / ____|        | |         | |
 | |  | |_ __   ___ _ __   | |     ___   __| | ___  ___| |_ ___
 | |  | | '_ \ / _ \ '_ \  | |    / _ \ / _` |/ _ \/ __| __/ __|
 | |__| | |_) |  __/ | | | | |___| (_) | (_| |  __/\__ \ |_\__ \
  \____/| .__/ \___|_| |_|  \_____\___/ \__,_|\___||___/\__|___/
        | |
        |_| Systemd Uninstall
EOF
    echo -e "${NC}"
    echo
}

# Check if services are installed
check_installed() {
    if [[ ! -f "$WEB_SERVICE" ]] && [[ ! -f "$UPGRADE_TIMER" ]]; then
        log_warn "OpenCode systemd services are not installed."
        log_info "Nothing to uninstall."
        exit 0
    fi
}

# Stop services
stop_services() {
    log_step "Stopping services..."
    
    systemctl --user stop opencode-web.service 2>/dev/null || true
    systemctl --user stop opencode-upgrade.timer 2>/dev/null || true
    systemctl --user stop opencode-upgrade.service 2>/dev/null || true
    
    log_success "Services stopped"
}

# Disable services
disable_services() {
    log_step "Disabling services..."
    
    systemctl --user disable opencode-web.service 2>/dev/null || true
    systemctl --user disable opencode-upgrade.timer 2>/dev/null || true
    
    log_success "Services disabled"
}

# Remove service files
remove_files() {
    log_step "Removing service files..."
    
    local removed=0
    
    if [[ -f "$WEB_SERVICE" ]]; then
        rm -f "$WEB_SERVICE"
        log_success "Removed: opencode-web.service"
        ((removed++)) || true
    fi
    
    if [[ -f "$UPGRADE_SERVICE" ]]; then
        rm -f "$UPGRADE_SERVICE"
        log_success "Removed: opencode-upgrade.service"
        ((removed++)) || true
    fi
    
    if [[ -f "$UPGRADE_TIMER" ]]; then
        rm -f "$UPGRADE_TIMER"
        log_success "Removed: opencode-upgrade.timer"
        ((removed++)) || true
    fi
    
    if [[ $removed -eq 0 ]]; then
        log_warn "No service files found to remove"
    fi
}

# Remove wizard script
remove_wizard() {
    log_step "Checking for wizard script..."
    
    local wizard_path="$OPENCODE_BIN_DIR/opencode-systemd-wizard"
    local symlink_path="$HOME/.local/bin/opencode-systemd"
    
    if [[ -f "$wizard_path" ]]; then
        rm -f "$wizard_path"
        log_success "Removed: $wizard_path"
    fi
    
    if [[ -L "$symlink_path" ]]; then
        rm -f "$symlink_path"
        log_success "Removed symlink: $symlink_path"
    fi
}

# Reload systemd
reload_daemon() {
    log_step "Reloading systemd daemon..."
    systemctl --user daemon-reload
    log_success "Daemon reloaded"
}

# Reset failed state
reset_failed() {
    log_step "Resetting failed states..."
    systemctl --user reset-failed opencode-web.service 2>/dev/null || true
    systemctl --user reset-failed opencode-upgrade.service 2>/dev/null || true
    systemctl --user reset-failed opencode-upgrade.timer 2>/dev/null || true
}

# Main uninstall
uninstall() {
    local auto_confirm="${AUTO_CONFIRM:-false}"
    local full_cleanup="${FULL_CLEANUP:-false}"
    
    print_banner
    
    check_installed
    
    if ! $auto_confirm; then
        echo -e "${YELLOW}⚠ This will remove the following:${NC}"
        echo
        echo "  • opencode-web.service (main web service)"
        echo "  • opencode-upgrade.service (upgrade handler)"
        echo "  • opencode-upgrade.timer (daily upgrade trigger)"
        if $full_cleanup; then
            echo "  • opencode-systemd-wizard (CLI tool)"
        fi
        echo
        
        read -p "Are you sure you want to uninstall? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "Uninstall cancelled."
            exit 0
        fi
    fi
    
    log_info "Starting uninstallation..."
    echo
    
    stop_services
    disable_services
    remove_files
    
    if $full_cleanup; then
        remove_wizard
    fi
    
    reload_daemon
    reset_failed
    
    echo
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  ✓ OpenCode Systemd uninstalled successfully${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════${NC}"
    echo
    
    if ! $full_cleanup; then
        log_info "Wizard script preserved at: $OPENCODE_BIN_DIR/opencode-systemd-wizard"
        log_info "To remove it too, run: rm $OPENCODE_BIN_DIR/opencode-systemd-wizard"
    fi
    
    log_info "Thanks for using OpenCode Systemd!"
    echo
}

# Show help
usage() {
    cat << EOF
OpenCode Systemd Uninstaller

Usage:
  curl -fsSL https://raw.githubusercontent.com/grikomsn/opencode-systemd/main/uninstall.sh | bash
  curl -fsSL https://raw.githubusercontent.com/grikomsn/opencode-systemd/main/uninstall.sh | bash -s -- [OPTIONS]

Options:
  -y, --yes         Auto-confirm without prompts
  --full            Also remove the wizard script
  -h, --help        Show this help message

Examples:
  # Interactive uninstall
  curl -fsSL https://raw.githubusercontent.com/grikomsn/opencode-systemd/main/uninstall.sh | bash

  # Uninstall without prompts
  curl -fsSL https://raw.githubusercontent.com/grikomsn/opencode-systemd/main/uninstall.sh | bash -s -- --yes

  # Full cleanup (remove services + wizard)
  curl -fsSL https://raw.githubusercontent.com/grikomsn/opencode-systemd/main/uninstall.sh | bash -s -- --full --yes
EOF
}

# Parse arguments
parse_args() {
    AUTO_CONFIRM=false
    FULL_CLEANUP=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes)
                AUTO_CONFIRM=true
                shift
                ;;
            --full)
                FULL_CLEANUP=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Run
parse_args "$@"
uninstall
