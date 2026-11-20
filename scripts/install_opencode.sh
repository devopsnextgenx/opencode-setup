#!/bin/sh

# Version
VERSION="1.1.0"

# Constants
DEST_DIR="$HOME/.config/opencode"
SOURCE_DIR="$(pwd)"

# Color support (checks if stdout is a terminal)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
else
    GREEN=''
    BLUE=''
    RED=''
    YELLOW=''
    NC=''
fi

printf_info() {
    printf "${BLUE}[INFO]${NC} %s...\n" "$1"
}

printf_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

printf_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

printf_warn() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

show_help() {
    printf "Opencode Setup Script\n"
    printf "Version: %s\n" "$VERSION"
    printf ""
    printf "Usage: %s [OPTION]\n" "$0"
    printf ""
    printf "Options:\n"
    printf "  -h, --help      Show this help message and exit\n"
    printf "  -v, --version   Show version information and exit\n"
    printf "  --uninstall      Uninstall opencode configuration\n"
    printf "  -y, --yes       Automatically say yes to prompts\n"
    printf ""
    printf "Example: %s --uninstall\n" "$0"
}

show_version() {
    printf "Opencode Setup Script Version %s\n" "$VERSION"
}

uninstall() {
    auto_confirm="$1"
    printf "${RED}[WARNING]${NC} This will remove all configuration files in %s\n" "$DEST_DIR"
    
    if [ "$auto_confirm" != "true" ]; then
        printf "Are you sure you want to proceed? (y/N) "
        read -r response
        case "$response" in
            [Yy]* ) ;;
            * ) printf "Uninstall cancelled.\n"; return 0 ;;
        esac
    fi

    printf_info "Uninstalling"
    rm -rf "$DEST_DIR/agents" "$DEST_DIR/skills" "$DEST_DIR/prompts" "$DEST_DIR/opencode.json"
    printf_success "Uninstalled successfully."
}

install_binary() {
    auto_confirm="$1"
    printf_info "Installing opencode binary"
    
    if [ "$auto_confirm" != "true" ]; then
        printf "Do you want to install opencode binary via curl? (y/N) "
        read -r response
        case "$response" in
            [Yy]* ) ;;
            * ) printf "Skipping binary installation.\n"; return 0 ;;
        esac
    fi

    if ! command -v curl >/dev/null 2>&1; then
        printf_error "curl is not installed. Please install curl and try again."
        return 1
    fi

    printf_info "Running installation script..."
    curl -fsSL https://opencode.ai/install | bash
    if [ $? -eq 0 ]; then
        printf_success "Binary installation completed."
    else
        printf_error "Binary installation failed."
        return 1
    fi
}

install_config() {
    auto_confirm="$1"
    printf_info "Starting configuration installation to %s" "$DEST_DIR"

    # Create target directory if it doesn't exist
    if [ ! -d "$DEST_DIR" ]; then
        printf_info "Creating directory %s" "$DEST_DIR"
        mkdir -p "$DEST_DIR"
    fi

    # Copying files
    printf_info "Copying agents"
    cp -r agents/ "$DEST_DIR/"

    printf_info "Copying skills"
    cp -r skills/ "$DEST_DIR/"

    printf_info "Copying prompts"
    cp -r prompts/ "$DEST_DIR/"

    printf_info "Copying opencode.json"
    cp opencode.json "$DEST_DIR/"

    printf_success "Configuration setup complete!"
}

# Main logic
AUTO_CONFIRM=false
CMD=""

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        --uninstall)
            CMD="uninstall"
            shift
            ;;
        -y|--yes)
            AUTO_CONFIRM=true
            shift
            ;;
        *)
            printf "${RED}[ERROR]${NC} Unknown option: %s\n" "$1"
            show_help
            exit 1
            ;;
    esac
done

# Execution
if [ "$CMD" = "uninstall" ]; then
    uninstall "$AUTO_CONFIRM"
else
    install_binary "$AUTO_CONFIRM"
    install_config "$AUTO_CONFIRM"
fi
