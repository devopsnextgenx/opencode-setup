#!/bin/sh

# Version
VERSION="1.0.0"

# Constants
DEST_DIR="$HOME/.grok"
ITEMS="agents skills config.toml"

# Locate the grok/ directory: the script's parent if config.toml is there,
# otherwise grok/ next to this script.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -e "$SCRIPT_DIR/config.toml" ]; then
    SOURCE_DIR="$SCRIPT_DIR"
elif [ -e "$SCRIPT_DIR/../config.toml" ]; then
    SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    printf '[ERROR] Could not find config.toml in %s or its parent\n' "$SCRIPT_DIR" >&2
    exit 1
fi

# Color support (checks if stdout is a terminal)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    GREEN=''
    BLUE=''
    RED=''
    YELLOW=''
    CYAN=''
    NC=''
fi

printf_info()    { printf '%b[INFO]%b %s...\n' "$BLUE" "$NC" "$1"; }
printf_success() { printf '%b[SUCCESS]%b %s\n' "$GREEN" "$NC" "$1"; }
printf_error()   { printf '%b[ERROR]%b %s\n' "$RED" "$NC" "$1" >&2; }
printf_warn()    { printf '%b[WARNING]%b %s\n' "$YELLOW" "$NC" "$1"; }
printf_dry()     { printf '%b[DRY-RUN]%b Would run: %s\n' "$CYAN" "$NC" "$1"; }

show_help() {
    cat <<EOF
Grok Setup Script
Version: $VERSION

Usage: $0 [OPTION]...

Copies grok/agents, grok/skills, and grok/config.toml to $DEST_DIR.
The grok binary is installed via curl, and configuration is copied to $DEST_DIR.

Options:
  -h, --help       Show this help message and exit
  -v, --version    Show version information and exit
  --uninstall      Remove the copied agents, skills, and config.toml
  -y, --yes        Automatically say yes to prompts
  --dry-run        Show what the script would do without making any changes
  --verify         After running, check that the result is correct and valid
  --force          Overwrite existing files (asks for confirmation first,
                   unless combined with -y)

Without --force, existing files in $DEST_DIR are left untouched.
--force replaces each destination item as a whole. Other files in
$DEST_DIR, such as auth.json and sessions/, are left in place.

Examples:
  $0 --dry-run
  $0 --verify
  $0 --force --verify
  $0 --uninstall --dry-run
EOF
}

show_version() {
    printf 'Grok Setup Script Version %s\n' "$VERSION"
}

# confirm PROMPT -> returns 0 if the user agrees (or AUTO_CONFIRM is set)
confirm() {
    if [ "$AUTO_CONFIRM" = "true" ]; then
        return 0
    fi
    printf '%s (y/N) ' "$1"
    read -r response
    case "$response" in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

# run CMD [ARGS...] -> executes, or only prints in dry-run mode
run() {
    if [ "$DRY_RUN" = "true" ]; then
        printf_dry "$*"
        return 0
    fi
    "$@"
}

# ---------------------------------------------------------------- verify

verify_toml() {
    file="$1"
    if ! command -v python3 >/dev/null 2>&1; then
        printf_warn "python3 not found; skipping TOML validation"
        return 0
    fi
    python3 -c 'import tomllib,sys; tomllib.load(open(sys.argv[1], "rb"))' "$file" >/dev/null 2>&1
}

verify_install() {
    printf_info "Verifying installation"
    failed=0

    for item in $ITEMS; do
        if [ ! -e "$DEST_DIR/$item" ]; then
            printf_error "Missing: $DEST_DIR/$item"
            failed=1
        elif ! diff -r "$SOURCE_DIR/$item" "$DEST_DIR/$item" >/dev/null 2>&1; then
            printf_error "Differs from source: $DEST_DIR/$item (re-run with --force to overwrite)"
            failed=1
        fi
    done

    if [ -f "$DEST_DIR/config.toml" ] && ! verify_toml "$DEST_DIR/config.toml"; then
        printf_error "config.toml is not valid TOML"
        failed=1
    fi

    if ! command -v grok >/dev/null 2>&1; then
        printf_warn "grok binary not found in PATH"
    fi

    if [ "$failed" -eq 0 ]; then
        printf_success "Verification passed"
    else
        printf_error "Verification failed"
    fi
    return "$failed"
}

verify_uninstall() {
    printf_info "Verifying removal"
    failed=0
    for item in $ITEMS; do
        if [ -e "$DEST_DIR/$item" ]; then
            printf_error "Still present: $DEST_DIR/$item"
            failed=1
        fi
    done
    if [ "$failed" -eq 0 ]; then
        printf_success "Verification passed"
    else
        printf_error "Verification failed"
    fi
    return "$failed"
}

# ---------------------------------------------------------------- actions

uninstall() {
    printf_warn "This will remove agents, skills, and config.toml in $DEST_DIR"

    if [ "$DRY_RUN" != "true" ]; then
        if ! confirm "Are you sure you want to proceed?"; then
            printf 'Uninstall cancelled.\n'
            return 0
        fi
    fi

    printf_info "Uninstalling"
    for item in $ITEMS; do
        run rm -rf "$DEST_DIR/$item"
    done
    printf_success "Uninstalled successfully."
}

# copy_item NAME -> copies one item, honoring --force and confirmation
copy_item() {
    name="$1"
    src="$SOURCE_DIR/$name"
    dest="$DEST_DIR/$name"

    if [ ! -e "$src" ]; then
        printf_error "Source not found: $src"
        return 1
    fi

    if [ -e "$dest" ]; then
        if [ "$FORCE" != "true" ]; then
            printf_warn "$dest already exists; skipping (use --force to overwrite)"
            return 0
        fi
        if [ "$DRY_RUN" != "true" ] && ! confirm "Overwrite existing $dest?"; then
            printf_warn "Skipped $dest"
            return 0
        fi
        run rm -rf "$dest"
    fi

    printf_info "Copying $name"
    run cp -R "$src" "$DEST_DIR/"
}

install_binary() {
    printf_info "Installing grok binary"

    if [ "$DRY_RUN" = "true" ]; then
        printf_dry "curl -fsSL https://x.ai/cli/install.sh | bash"
        return 0
    fi

    if ! confirm "Do you want to install grok binary via curl?"; then
        printf 'Skipping binary installation.\n'
        return 0
    fi

    if ! command -v curl >/dev/null 2>&1; then
        printf_error "curl is not installed. Please install curl and try again."
        return 1
    fi

    printf_info "Running installation script"
    if curl -fsSL https://x.ai/cli/install.sh | bash; then
        printf_success "Binary installation completed."
    else
        printf_error "Binary installation failed."
        return 1
    fi
}

install_config() {
    printf_info "Starting configuration installation to $DEST_DIR"

    if [ ! -d "$DEST_DIR" ]; then
        printf_info "Creating directory $DEST_DIR"
        run mkdir -p "$DEST_DIR"
    fi

    status=0
    for item in $ITEMS; do
        copy_item "$item" || status=1
    done

    if [ "$status" -eq 0 ]; then
        printf_success "Configuration setup complete!"
    else
        printf_error "Configuration setup finished with errors."
    fi
    return "$status"
}

# ---------------------------------------------------------------- main

AUTO_CONFIRM=false
DRY_RUN=false
VERIFY=false
FORCE=false
CMD=""

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)    show_help; exit 0 ;;
        -v|--version) show_version; exit 0 ;;
        --uninstall)  CMD="uninstall"; shift ;;
        -y|--yes)     AUTO_CONFIRM=true; shift ;;
        --dry-run)    DRY_RUN=true; shift ;;
        --verify)     VERIFY=true; shift ;;
        --force)      FORCE=true; shift ;;
        *)
            printf_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

if [ "$DRY_RUN" = "true" ]; then
    printf_warn "Dry-run mode: no changes will be made"
fi

EXIT=0
if [ "$CMD" = "uninstall" ]; then
    uninstall || EXIT=1
    if [ "$VERIFY" = "true" ] && [ "$DRY_RUN" != "true" ]; then
        verify_uninstall || EXIT=1
    fi
else
    install_binary || EXIT=1
    install_config || EXIT=1
    if [ "$VERIFY" = "true" ] && [ "$DRY_RUN" != "true" ]; then
        verify_install || EXIT=1
    fi
fi

if [ "$VERIFY" = "true" ] && [ "$DRY_RUN" = "true" ]; then
    printf_warn "--verify skipped in dry-run mode (nothing was changed)"
fi

exit "$EXIT"
