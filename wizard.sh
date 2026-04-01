#!/usr/bin/env bash
#
# OpenCode Systemd Wizard
# A CLI tool to manage OpenCode web service with systemd auto-upgrade
#
# Repository: https://github.com/grikomsn/opencode-systemd
# License: MIT
#

set -euo pipefail

# Version
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Paths
USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
OPENCODE_DIR="$HOME/.opencode"
OPENCODE_BIN="$OPENCODE_DIR/bin/opencode"
OPENCODE_WEB_SERVICE="$OPENCODE_DIR/bin/opencode-web-service"

# Service files
WEB_SERVICE="$USER_SYSTEMD_DIR/opencode-web.service"
UPGRADE_SERVICE="$USER_SYSTEMD_DIR/opencode-upgrade.service"
UPGRADE_TIMER="$USER_SYSTEMD_DIR/opencode-upgrade.timer"

# Default configuration
UPGRADE_TIME="05:00:00"
WEB_PORT="4096"
WEB_HOST="127.0.0.1"
AUTO_CONFIRM=false

#######################################
# Utility Functions
#######################################

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

log_header() {
    echo -e "${BOLD}${CYAN}$1${NC}"
}

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if opencode is installed
    if [[ ! -x "$OPENCODE_BIN" ]]; then
        log_error "OpenCode not found at $OPENCODE_BIN"
        log_info "Please install OpenCode first:"
        log_info "  curl -fsSL https://get.opencode.ai | bash"
        exit 1
    fi
    log_success "OpenCode found at $OPENCODE_BIN"
    
    # Check if systemd is available
    if ! command -v systemctl &> /dev/null; then
        log_error "systemctl not found. This wizard requires systemd."
        exit 1
    fi
    log_success "systemctl available"
    
    # Check user systemd directory
    if [[ ! -d "$USER_SYSTEMD_DIR" ]]; then
        log_step "Creating systemd user directory..."
        mkdir -p "$USER_SYSTEMD_DIR"
    fi
    log_success "Systemd user directory ready"
    
    # Check if web service binary exists
    if [[ ! -x "$OPENCODE_WEB_SERVICE" ]]; then
        log_warn "opencode-web-service script not found at $OPENCODE_WEB_SERVICE"
        log_info "The wizard will still work, but the web service may fail."
    fi
}

#######################################
# Configuration Functions
#######################################

prompt_for_config() {
    echo
    log_header "═══════════════════════════════════════════════"
    log_header "  OpenCode Systemd Configuration"
    log_header "═══════════════════════════════════════════════"
    echo
    
    # Auto-upgrade schedule
    echo -e "${YELLOW}Auto-upgrade Schedule${NC}"
    echo "Current: Daily at $UPGRADE_TIME"
    read -p "Enter new time (HH:MM:SS, e.g., 05:00:00) or press Enter to keep: " new_time
    if [[ -n "$new_time" ]]; then
        if [[ "$new_time" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
            UPGRADE_TIME="$new_time"
            log_success "Upgrade time set to: $UPGRADE_TIME"
        else
            log_warn "Invalid time format. Keeping $UPGRADE_TIME"
        fi
    fi
    
    echo
    
    # Web service configuration
    echo -e "${YELLOW}Web Service Configuration${NC}"
    echo "Current host: $WEB_HOST"
    read -p "Enter new host or press Enter to keep ($WEB_HOST): " new_host
    [[ -n "$new_host" ]] && WEB_HOST="$new_host"
    
    echo "Current port: $WEB_PORT"
    read -p "Enter new port or press Enter to keep ($WEB_PORT): " new_port
    [[ -n "$new_port" ]] && WEB_PORT="$new_port"
    
    echo
    log_success "Configuration complete!"
    echo "  - Auto-upgrade: Daily at $UPGRADE_TIME"
    echo "  - Web service: $WEB_HOST:$WEB_PORT"
    echo
}

#######################################
# Service File Generators
#######################################

generate_web_service() {
    cat << EOF
[Unit]
Description=OpenCode web UI bound to $WEB_HOST
Wants=network-online.target
After=network-online.target
Documentation=https://github.com/grikomsn/opencode-systemd

[Service]
Type=simple
WorkingDirectory=%h/.opencode
ExecStartPre=%h/.opencode/bin/opencode upgrade
ExecStart=$OPENCODE_WEB_SERVICE
Restart=on-failure
RestartSec=5
TimeoutStopSec=30

[Install]
WantedBy=default.target
EOF
}

generate_upgrade_service() {
    cat << EOF
[Unit]
Description=OpenCode upgrade and restart service
Documentation=https://github.com/grikomsn/opencode-systemd

[Service]
Type=oneshot
ExecStart=%h/.opencode/bin/opencode upgrade
ExecStartPost=-systemctl --user restart opencode-web.service
EOF
}

generate_upgrade_timer() {
    cat << EOF
[Unit]
Description=OpenCode auto-upgrade trigger
Documentation=https://github.com/grikomsn/opencode-systemd

[Timer]
OnCalendar=daily
OnCalendar=*-*-* $UPGRADE_TIME
Persistent=true

[Install]
WantedBy=timers.target
EOF
}

#######################################
# Action Functions
#######################################

do_install() {
    echo
    log_header "═══════════════════════════════════════════════"
    log_header "  Installing OpenCode Systemd Services"
    log_header "═══════════════════════════════════════════════"
    echo
    
    check_prerequisites
    
    # Check if already installed
    if [[ -f "$WEB_SERVICE" ]] || [[ -f "$UPGRADE_TIMER" ]]; then
        log_warn "Services already exist!"
        if ! $AUTO_CONFIRM; then
            read -p "Overwrite existing configuration? [y/N]: " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                log_info "Installation cancelled."
                return
            fi
        fi
        do_uninstall --keep-files
    fi
    
    # Get configuration
    if ! $AUTO_CONFIRM; then
        prompt_for_config
    fi
    
    # Create service files
    log_step "Creating service files..."
    
    generate_web_service > "$WEB_SERVICE"
    log_success "Created: opencode-web.service"
    
    generate_upgrade_service > "$UPGRADE_SERVICE"
    log_success "Created: opencode-upgrade.service"
    
    generate_upgrade_timer > "$UPGRADE_TIMER"
    log_success "Created: opencode-upgrade.timer"
    
    # Reload systemd
    log_step "Reloading systemd daemon..."
    systemctl --user daemon-reload
    log_success "Daemon reloaded"
    
    # Enable and start services
    log_step "Enabling services..."
    systemctl --user enable opencode-web.service
    systemctl --user enable opencode-upgrade.timer
    log_success "Services enabled (auto-start on boot)"
    
    log_step "Starting services..."
    systemctl --user start opencode-upgrade.timer
    log_success "Auto-upgrade timer started"
    
    local start_web=true
    if ! $AUTO_CONFIRM; then
        read -p "Start the web service now? [Y/n]: " response
        [[ "$response" =~ ^[Nn]$ ]] && start_web=false
    fi
    
    if $start_web; then
        systemctl --user start opencode-web.service
        log_success "Web service started"
        log_info "Access OpenCode web UI at: http://$WEB_HOST:$WEB_PORT"
    else
        log_info "Web service not started (run 'systemctl --user start opencode-web.service' to start)"
    fi
    
    echo
    echo -e "${GREEN}${BOLD}✓ Installation complete!${NC}"
    echo
    do_status
}

do_update() {
    echo
    log_header "═══════════════════════════════════════════════"
    log_header "  Updating OpenCode Systemd Configuration"
    log_header "═══════════════════════════════════════════════"
    echo
    
    # Check if installed
    if [[ ! -f "$WEB_SERVICE" ]]; then
        log_error "OpenCode services not installed. Run install first."
        return 1
    fi
    
    if ! $AUTO_CONFIRM; then
        echo "What would you like to update?"
        echo "  1) Update service configuration (time, host, port)"
        echo "  2) Update OpenCode binary and restart services"
        echo "  3) Reload systemd and restart services"
        echo
        read -p "Enter choice [1-3]: " choice
    else
        choice="3"
    fi
    
    case $choice in
        1)
            log_step "Updating configuration..."
            prompt_for_config
            
            # Stop services
            systemctl --user stop opencode-web.service 2>/dev/null || true
            systemctl --user stop opencode-upgrade.timer 2>/dev/null || true
            
            # Regenerate files
            generate_web_service > "$WEB_SERVICE"
            generate_upgrade_timer > "$UPGRADE_TIMER"
            
            systemctl --user daemon-reload
            systemctl --user start opencode-upgrade.timer
            systemctl --user start opencode-web.service
            
            log_success "Configuration updated and services restarted"
            ;;
        2)
            log_step "Upgrading OpenCode..."
            "$OPENCODE_BIN" upgrade
            log_step "Restarting services..."
            systemctl --user restart opencode-web.service
            log_success "OpenCode updated and services restarted"
            ;;
        3)
            log_step "Reloading systemd..."
            systemctl --user daemon-reload
            log_step "Restarting services..."
            systemctl --user restart opencode-web.service
            systemctl --user restart opencode-upgrade.timer
            log_success "Services restarted"
            ;;
        *)
            log_error "Invalid choice"
            return 1
            ;;
    esac
    
    do_status
}

do_uninstall() {
    local keep_files=false
    [[ "${1:-}" == "--keep-files" ]] && keep_files=true
    
    echo
    log_header "═══════════════════════════════════════════════"
    log_header "  Uninstalling OpenCode Systemd Services"
    log_header "═══════════════════════════════════════════════"
    echo
    
    if [[ ! -f "$WEB_SERVICE" ]]; then
        log_warn "Services not installed."
        return
    fi
    
    if [[ "$keep_files" == false ]] && ! $AUTO_CONFIRM; then
        read -p "Are you sure you want to uninstall? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "Uninstall cancelled."
            return
        fi
    fi
    
    log_step "Stopping services..."
    systemctl --user stop opencode-web.service 2>/dev/null || true
    systemctl --user stop opencode-upgrade.timer 2>/dev/null || true
    systemctl --user stop opencode-upgrade.service 2>/dev/null || true
    log_success "Services stopped"
    
    log_step "Disabling services..."
    systemctl --user disable opencode-web.service 2>/dev/null || true
    systemctl --user disable opencode-upgrade.timer 2>/dev/null || true
    log_success "Services disabled"
    
    if [[ "$keep_files" == false ]]; then
        log_step "Removing service files..."
        rm -f "$WEB_SERVICE" "$UPGRADE_SERVICE" "$UPGRADE_TIMER"
        log_success "Service files removed"
        
        log_step "Reloading systemd daemon..."
        systemctl --user daemon-reload
        log_success "Daemon reloaded"
    fi
    
    echo
    echo -e "${GREEN}${BOLD}✓ Uninstall complete!${NC}"
}

do_status() {
    echo
    log_header "═══════════════════════════════════════════════"
    log_header "  OpenCode Systemd Status"
    log_header "═══════════════════════════════════════════════"
    echo
    
    # Check installation
    echo -e "${YELLOW}${BOLD}Installation Status:${NC}"
    if [[ -f "$WEB_SERVICE" ]]; then
        log_success "opencode-web.service installed"
    else
        log_warn "opencode-web.service not installed"
    fi
    
    if [[ -f "$UPGRADE_SERVICE" ]]; then
        log_success "opencode-upgrade.service installed"
    else
        log_warn "opencode-upgrade.service not installed"
    fi
    
    if [[ -f "$UPGRADE_TIMER" ]]; then
        log_success "opencode-upgrade.timer installed"
    else
        log_warn "opencode-upgrade.timer not installed"
    fi
    
    echo
    echo -e "${YELLOW}${BOLD}Service Status:${NC}"
    
    # Web service status
    if systemctl --user is-active opencode-web.service &>/dev/null; then
        log_success "opencode-web.service: RUNNING"
        systemctl --user status opencode-web.service --no-pager 2>/dev/null | grep -E "(Active:|Memory:|CPU:|Main PID:)" || true
    else
        log_warn "opencode-web.service: STOPPED"
    fi
    
    echo
    
    # Timer status
    if systemctl --user is-active opencode-upgrade.timer &>/dev/null; then
        log_success "opencode-upgrade.timer: ACTIVE"
        systemctl --user list-timers opencode-upgrade.timer --no-pager 2>/dev/null | head -5 || true
    else
        log_warn "opencode-upgrade.timer: INACTIVE"
    fi
    
    echo
    echo -e "${YELLOW}${BOLD}Configuration:${NC}"
    if [[ -f "$UPGRADE_TIMER" ]]; then
        local schedule
        schedule=$(grep "OnCalendar=\*-\*-\*" "$UPGRADE_TIMER" | cut -d' ' -f2 || echo "$UPGRADE_TIME")
        echo "  Auto-upgrade time: $schedule"
    fi
    if [[ -f "$WEB_SERVICE" ]]; then
        grep "Description=" "$WEB_SERVICE" | head -1 | sed 's/Description=/  Service: /'
        grep "ExecStart=" "$WEB_SERVICE" | grep -v "ExecStartPre" | head -1 | sed 's|ExecStart=.*bin/|  Binary: |'
    fi
    
    echo
}

do_logs() {
    echo
    log_header "═══════════════════════════════════════════════"
    log_header "  Viewing OpenCode Logs"
    log_header "═══════════════════════════════════════════════"
    echo
    
    if ! $AUTO_CONFIRM; then
        echo "Select log to view:"
        echo "  1) Web service logs (follow mode)"
        echo "  2) Upgrade service logs (last 50 lines)"
        echo "  3) All OpenCode logs (last 100 lines)"
        echo "  4) Back to menu"
        echo
        read -p "Enter choice [1-4]: " choice
    else
        choice="3"
    fi
    
    case $choice in
        1)
            echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
            journalctl --user -u opencode-web.service -f
            ;;
        2)
            journalctl --user -u opencode-upgrade.service -n 50 --no-pager
            ;;
        3)
            journalctl --user -u opencode-web.service -u opencode-upgrade.service -u opencode-upgrade.timer -n 100 --no-pager
            ;;
        4)
            return
            ;;
        *)
            log_error "Invalid choice"
            ;;
    esac
}

do_upgrade_now() {
    echo
    log_header "═══════════════════════════════════════════════"
    log_header "  Manual Upgrade"
    log_header "═══════════════════════════════════════════════"
    echo
    
    log_step "Running opencode upgrade..."
    "$OPENCODE_BIN" upgrade
    
    log_step "Restarting web service..."
    systemctl --user restart opencode-web.service
    
    log_success "Upgrade complete!"
    do_status
}

#######################################
# Main Menu
#######################################

show_menu() {
    echo
    echo -e "${MAGENTA}${BOLD}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}${BOLD}║${NC}   ${CYAN}${BOLD}OpenCode Systemd Wizard v${VERSION}${NC}              ${MAGENTA}${BOLD}║${NC}"
    echo -e "${MAGENTA}${BOLD}╚═══════════════════════════════════════════════╝${NC}"
    echo
    echo "  1) Install    - Set up systemd services"
    echo "  2) Update     - Change config or restart"
    echo "  3) Uninstall  - Remove all services"
    echo "  4) Status     - Check service status"
    echo "  5) Logs       - View service logs"
    echo "  6) Upgrade    - Run upgrade and restart"
    echo
    echo "  0) Exit"
    echo
}

run_interactive() {
    while true; do
        show_menu
        read -p "Enter your choice [0-6]: " choice
        
        case $choice in
            1) do_install ;;
            2) do_update ;;
            3) do_uninstall ;;
            4) do_status ;;
            5) do_logs ;;
            6) do_upgrade_now ;;
            0) 
                echo
                log_info "Goodbye! 👋"
                exit 0
                ;;
            *)
                log_error "Invalid choice. Please enter 0-6."
                ;;
        esac
        
        if ! $AUTO_CONFIRM; then
            echo
            read -p "Press Enter to continue..."
        fi
    done
}

#######################################
# CLI Mode
#######################################

show_help() {
    cat << EOF
${BOLD}OpenCode Systemd Wizard v${VERSION}${NC}

A CLI tool to manage OpenCode web service with systemd auto-upgrade.

${BOLD}Usage:${NC}
  $(basename "$0") [COMMAND] [OPTIONS]

${BOLD}Commands:${NC}
  install     Install and configure systemd services
  update      Update configuration or restart services
  uninstall   Remove all systemd services
  status      Show current service status
  logs        View service logs
  upgrade     Run manual upgrade now
  version     Show version information

${BOLD}Options:${NC}
  -h, --help       Show this help message
  -y, --yes        Auto-confirm prompts (for scripts)
  --time HH:MM:SS  Set upgrade time (default: 05:00:00)
  --host HOST      Set web service host (default: 127.0.0.1)
  --port PORT      Set web service port (default: 4096)

${BOLD}Examples:${NC}
  # Interactive wizard
  $(basename "$0")

  # Install with prompts
  $(basename "$0") install

  # Install with defaults, no prompts
  $(basename "$0") install --yes

  # Install with custom settings
  $(basename "$0") install --time 03:00:00 --host 0.0.0.0 --port 8080

  # Quick status check
  $(basename "$0") status

  # Uninstall without confirmation
  $(basename "$0") uninstall --yes

  # Run manual upgrade
  $(basename "$0") upgrade

${BOLD}Repository:${NC} https://github.com/grikomsn/opencode-systemd
EOF
}

# Parse command line arguments
COMMAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        install|update|uninstall|status|logs|upgrade)
            COMMAND="$1"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version|version)
            echo "OpenCode Systemd Wizard v${VERSION}"
            exit 0
            ;;
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
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Print banner on start
print_banner() {
    echo -e "${MAGENTA}"
    cat << 'EOF'
   ____                      _____          _           _
  / __ \                    / ____|        | |         | |
 | |  | |_ __   ___ _ __   | |     ___   __| | ___  ___| |_ ___
 | |  | | '_ \ / _ \ '_ \  | |    / _ \ / _` |/ _ \/ __| __/ __|
 | |__| | |_) |  __/ | | | | |___| (_) | (_| |  __/\__ \ |_\__ \
  \____/| .__/ \___|_| |_|  \_____\___/ \__,_|\___||___/\__|___/
        | |
        |_| Systemd Wizard
EOF
    echo -e "${NC}"
    echo -e "${CYAN}Version ${VERSION} • https://github.com/grikomsn/opencode-systemd${NC}"
    echo
}

# Run command or interactive mode
if [[ -n "$COMMAND" ]]; then
    case $COMMAND in
        install) 
            if $AUTO_CONFIRM; then
                print_banner
                check_prerequisites
                generate_web_service > "$WEB_SERVICE"
                generate_upgrade_service > "$UPGRADE_SERVICE"
                generate_upgrade_timer > "$UPGRADE_TIMER"
                systemctl --user daemon-reload
                systemctl --user enable opencode-web.service
                systemctl --user enable opencode-upgrade.timer
                systemctl --user start opencode-upgrade.timer
                systemctl --user start opencode-web.service
                log_success "Installation complete!"
                do_status
            else
                print_banner
                do_install
            fi
            ;;
        update) 
            print_banner
            do_update 
            ;;
        uninstall) 
            print_banner
            if $AUTO_CONFIRM; then
                do_uninstall --keep-files
                do_uninstall
            else
                do_uninstall
            fi
            ;;
        status) 
            do_status 
            ;;
        logs) 
            print_banner
            do_logs 
            ;;
        upgrade) 
            print_banner
            do_upgrade_now 
            ;;
        help) 
            print_banner
            show_help 
            ;;
    esac
else
    # Interactive mode
    print_banner
    run_interactive
fi
