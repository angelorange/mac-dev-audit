#!/bin/bash
# Configuration defaults and loading

# Configuration file locations (in order of priority)
CONFIG_SYSTEM="/etc/mac-dev-audit/config"
CONFIG_USER="$HOME/.config/mac-dev-audit/config"

# Load configuration from file
load_config_file() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        return 0
    fi

    log_debug "Loading config from: $config_file"

    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace
        key=$(trim "$key")
        value=$(trim "$value")

        # Remove quotes from value
        value="${value#\"}"
        value="${value%\"}"
        value="${value#\'}"
        value="${value%\'}"

        case "$key" in
            threshold_gb)
                THRESHOLD_GB="$value"
                ;;
            output_format)
                OUTPUT_FORMAT="$value"
                ;;
            verbose)
                VERBOSE="$value"
                ;;
            *)
                log_debug "Unknown config key: $key"
                ;;
        esac
    done < "$config_file"
}

# Load default configuration
load_defaults() {
    local script_dir="$1"
    local defaults_file="$script_dir/config/defaults.conf"

    if [[ -f "$defaults_file" ]]; then
        load_config_file "$defaults_file"
    fi
}

# Load all configurations (layered)
load_config() {
    local script_dir="$1"

    # 1. Built-in defaults
    load_defaults "$script_dir"

    # 2. System config
    load_config_file "$CONFIG_SYSTEM"

    # 3. User config
    load_config_file "$CONFIG_USER"

    # 4. CLI flags override everything (handled in args.sh)
}

# Get bloat patterns from file
get_bloat_patterns() {
    local script_dir="$1"
    local patterns_file="$script_dir/patterns/bloat-patterns.txt"

    if [[ ! -f "$patterns_file" ]]; then
        log_warn "Bloat patterns file not found: $patterns_file"
        return 1
    fi

    # Return patterns (excluding comments and empty lines)
    grep -v '^[[:space:]]*#' "$patterns_file" | grep -v '^[[:space:]]*$'
}

# Parse a bloat pattern line
# Format: pattern|category|explanation
parse_bloat_pattern() {
    local line="$1"
    local field="$2"  # 1=pattern, 2=category, 3=explanation

    echo "$line" | cut -d'|' -f"$field"
}
