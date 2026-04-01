#!/usr/bin/env bash
#
# OpenCode Systemd - One-line Installer
# Quick install script for opencode-systemd services
#
# Usage: curl -fsSL https://raw.githubusercontent.com/grikomsn/opencode-systemd/main/install.sh | bash
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

# Repository URL
REPO_URL="https://github.com/grikomsn/opencode-systemd"
RAW_URL="https://raw.githubusercontent.com/grikomsn/opencode-systemd/main"

# Version
VERSION="1.0.0"

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
        |_| Systemd Install
EOF
    echo -e "${NC}"
    echo -e "${BOLD}Version ${VERSION}${NC}"
    echo -e "${CYAN}${REPO_URL}${NC}"
    echo
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if opencode is installed
    if [[ ! -x "$HOME/.opencode/bin/opencode" ]]; then
        log_error "OpenCode is not installed!"
        echo
        log_info "Please install OpenCode first:"
        echo
        echo "  ${BOLD}curl -fsSL https://get.opencode.ai | bash${NC}"
        echo
        log_info "Then run this installer again."
        exit 1
    fi
    log_success "OpenCode is installed"
    
    # Check if systemd is available
    if ! command -v systemctl &> /dev/null; then
        log_error "systemd is not available on this system."
        exit 1
    fi
    log_success "systemd is available"
    
    # Check for required tools
    for cmd in curl wget; do
        if command -v $cmd &> /dev/null; then
            DOWNLOAD_CMD=$cmd
            break
        fi
    done
    
    if [[ -z "${DOWNLOAD_CMD:-}" ]]; then
        log_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    log_success "Download tool available: $DOWNLOAD_CMD"
}

# Download wizard script
download_wizard() {
    local wizard_path="$HOME/.opencode/bin/opencode-systemd-wizard"
    local temp_file
    temp_file=$(mktemp)
    
    log_step "Downloading wizard script..."
    
    if [[ "$DOWNLOAD_CMD" == "curl" ]]; then
        if curl -fsSL "${RAW_URL}/wizard.sh" -o "$temp_file" 2>/dev/null; then
            log_success "Downloaded wizard.sh"
        else
            log_error "Failed to download wizard script"
            rm -f "$temp_file"
            exit 1
        fi
    else
        if wget -q "${RAW_URL}/wizard.sh" -O "$temp_file" 2>/dev/null; then
            log_success "Downloaded wizard.sh"
        else
            log_error "Failed to download wizard script"
            rm -f "$temp_file"
            exit 1
        fi
    fi
    
    # Install wizard
    mkdir -p "$HOME/.opencode/bin"
    mv "$temp_file" "$wizard_path"
    chmod +x "$wizard_path"
    log_success "Installed wizard to $wizard_path"
    
    # Create symlink if not exists
    local bin_dir="$HOME/.local/bin"
    if [[ -d "$bin_dir" ]] && [[ ! -L "$bin_dir/opencode-systemd" ]]; then
        ln -sf "$wizard_path" "$bin_dir/opencode-systemd"
        log_success "Created symlink: $bin_dir/opencode-systemd"
    fi
    
    echo "$wizard_path"
}

# Install systemd services
install_services() {
    local wizard_path="$1"
    local auto_confirm="${AUTO_CONFIRM:-false}"
    local upgrade_time="${UPGRADE_TIME:-05:00:00}"
    local web_host="${WEB_HOST:-127.0.0.1}"
    local web_port="${WEB_PORT:-4096}"
    
    log_step "Installing systemd services..."
    
    if $auto_confirm; then
        "$wizard_path" install --yes --time "$upgrade_time" --host "$web_host" --port "$web_port"
    else
        "$wizard_path" install --time "$upgrade_time" --host "$web_host" --port "$web_port"
    fi
}

# Print usage
usage() {
    cat << EOF
OpenCode Systemd Installer

Usage: 
  curl -fsSL ${RAW_URL}/install.sh | bash
  curl -fsSL ${RAW_URL}/install.sh | bash -s -- [OPTIONS]

Options:
  -y, --yes              Auto-confirm all prompts
  --time HH:MM:SS        Set auto-upgrade time (default: 05:00:00)
  --host HOST            Set web service host (default: 127.0.0.1)
  --port PORT            Set web service port (default: 4096)
  -h, --help             Show this help message

Examples:
  # Install with defaults
  curl -fsSL ${RAW_URL}/install.sh | bash

  # Install without prompts
  curl -fsSL ${RAW_URL}/install.sh | bash -s -- --yes

  # Install with custom time
  curl -fsSL ${RAW_URL}/install.sh | bash -s -- --time 03:00:00

  # Install with custom host and port
  curl -fsSL ${RAW_URL}/install.sh | bash -s -- --host 0.0.0.0 --port 8080

After installation:
  - Web UI: http://127.0.0.1:4096 (or your custom host:port)
  - Auto-upgrade: Daily at configured time
  
  Run 'opencode-systemd status' to check status
  Run 'opencode-systemd --help' for more commands
EOF
}

# Parse arguments
parse_args() {
    AUTO_CONFIRM=false
    UPGRADE_TIME="05:00:00"
    WEB_HOST="127.0.0.1"
    WEB_PORT="4096"
    SHOW_HELP=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes)
                AUTO_CONFIRM=true
                shift
                ;;
            --time)
                UPGRADE_TIME="$2"
                shift 2
                ;;
            --host)
                WEB_HOST="$2"
                shift 2
                ;;
            --port)
                WEB_PORT="$2"
                shift 2
                ;;
            -h|--help)
                SHOW_HELP=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Main installation
main() {
    # Always parse args first (handles both pipe and direct execution)
    parse_args "$@"
    
    # Show help and exit if requested
    if $SHOW_HELP; then
        usage
        exit 0
    fi
    
    print_banner
    
    log_info "Starting installation..."
    echo
    
    check_prerequisites
    
    local wizard_path
    wizard_path=$(download_wizard)
    
    install_services "$wizard_path"
    
    echo
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  ✓ OpenCode Systemd installed successfully!${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════${NC}"
    echo
    log_info "Quick commands:"
    echo "  opencode-systemd status     # Check service status"
    echo "  opencode-systemd upgrade    # Manual upgrade"
    echo "  opencode-systemd --help     # Show all commands"
    echo
    log_info "Web UI: http://${WEB_HOST}:${WEB_PORT}"
    log_info "Auto-upgrade: Daily at ${UPGRADE_TIME}"
    echo
    log_info "For issues: ${REPO_URL}/issues"
}

# Run main
main "$@"
