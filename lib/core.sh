#!/bin/bash
# Core utilities: colors, output, error handling
# Compatible with bash 3.2+ (macOS default)

# Version
VERSION="1.0.0"

# Colors (using tput for portability)
if [[ -t 1 ]] && command -v tput &>/dev/null; then
    COLOR_RED=$(tput setaf 1)
    COLOR_GREEN=$(tput setaf 2)
    COLOR_YELLOW=$(tput setaf 3)
    COLOR_BLUE=$(tput setaf 4)
    COLOR_MAGENTA=$(tput setaf 5)
    COLOR_CYAN=$(tput setaf 6)
    COLOR_WHITE=$(tput setaf 7)
    COLOR_BOLD=$(tput bold)
    COLOR_DIM=$(tput dim)
    COLOR_RESET=$(tput sgr0)
else
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_BLUE=""
    COLOR_MAGENTA=""
    COLOR_CYAN=""
    COLOR_WHITE=""
    COLOR_BOLD=""
    COLOR_DIM=""
    COLOR_RESET=""
fi

# Error handling
set -o pipefail

# Log levels
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO

# Logging functions
log_debug() {
    [[ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_DEBUG ]] && echo "${COLOR_DIM}[DEBUG]${COLOR_RESET} $*" >&2
    return 0
}

log_info() {
    [[ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_INFO ]] && echo "${COLOR_BLUE}[INFO]${COLOR_RESET} $*" >&2
    return 0
}

log_warn() {
    [[ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_WARN ]] && echo "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*" >&2
    return 0
}

log_error() {
    [[ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_ERROR ]] && echo "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
    return 0
}

# Die with error message
die() {
    log_error "$@"
    exit 1
}

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Require a command or die
require_command() {
    local cmd="$1"
    local package="${2:-$1}"
    if ! command_exists "$cmd"; then
        die "Required command '$cmd' not found. Please install $package."
    fi
}

# Convert bytes to human-readable format
bytes_to_human() {
    local bytes="$1"
    if [[ $bytes -ge 1099511627776 ]]; then
        printf "%.1f TB" "$(echo "scale=1; $bytes / 1099511627776" | bc)"
    elif [[ $bytes -ge 1073741824 ]]; then
        printf "%.1f GB" "$(echo "scale=1; $bytes / 1073741824" | bc)"
    elif [[ $bytes -ge 1048576 ]]; then
        printf "%.1f MB" "$(echo "scale=1; $bytes / 1048576" | bc)"
    elif [[ $bytes -ge 1024 ]]; then
        printf "%.1f KB" "$(echo "scale=1; $bytes / 1024" | bc)"
    else
        printf "%d B" "$bytes"
    fi
}

# Convert GB to bytes
gb_to_bytes() {
    local gb="$1"
    echo "$((gb * 1073741824))"
}

# Get script directory (resolving symlinks)
get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    local dir
    while [[ -L "$source" ]]; do
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" && pwd
}

# Trim whitespace
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

# Check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        die "This tool is designed for macOS only."
    fi
}

# Get macOS version
get_macos_version() {
    sw_vers -productVersion
}

# Check minimum macOS version (12.0 = Monterey)
check_macos_version() {
    local min_version="${1:-12.0}"
    local current_version
    current_version=$(get_macos_version)

    if [[ "$(printf '%s\n' "$min_version" "$current_version" | sort -V | head -n1)" != "$min_version" ]]; then
        log_warn "This tool is tested on macOS $min_version+. Current: $current_version"
    fi
}

# Safe temporary file creation
create_temp_file() {
    mktemp -t "mac-dev-audit.XXXXXX"
}

# Temporary files tracking (simple approach for bash 3.2 compatibility)
TEMP_FILES_LIST=""

cleanup() {
    if [[ -n "$TEMP_FILES_LIST" ]]; then
        echo "$TEMP_FILES_LIST" | while read -r f; do
            [[ -f "$f" ]] && rm -f "$f"
        done
    fi
}

trap cleanup EXIT

register_temp_file() {
    TEMP_FILES_LIST="${TEMP_FILES_LIST}${1}
"
}
