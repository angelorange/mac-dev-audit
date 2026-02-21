#!/bin/bash
# CLI argument parsing

# Default values (can be overridden by config)
THRESHOLD_GB="${THRESHOLD_GB:-1}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-human}"
REPORT_FILE=""
VERBOSE="${VERBOSE:-false}"
SELECTED_MODULES=""

# Show help
show_help() {
    cat << 'EOF'
macOS Dev Audit Tool - Developer environment diagnostics

USAGE:
    mac-dev-audit [OPTIONS]

OPTIONS:
    --threshold <GB>    Size threshold for directory warnings (default: 1)
    --json              Output in JSON format
    --report <file>     Write report to file
    --help, -h          Show this help message
    --version, -v       Show version
    --verbose           Show detailed output
    --modules <list>    Run specific modules only (comma-separated)
                        Available: disk,memory,processes,directories,bloat

EXAMPLES:
    mac-dev-audit                           # Run all diagnostics
    mac-dev-audit --json                    # Output as JSON
    mac-dev-audit --threshold 2             # Warn for dirs > 2GB
    mac-dev-audit --modules disk,memory     # Run only disk and memory
    mac-dev-audit --report ~/audit.txt      # Save report to file

MODULES:
    disk          Disk usage analysis
    memory        Memory and swap diagnostics
    processes     Heavy process detection
    directories   Large directory finder
    bloat         Dev bloat pattern detection

For more information, visit: https://github.com/your-repo/mac-dev-audit
EOF
}

# Show version
show_version() {
    echo "mac-dev-audit version $VERSION"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --threshold)
                if [[ -z "$2" || "$2" == --* ]]; then
                    die "--threshold requires a numeric value"
                fi
                if ! [[ "$2" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                    die "--threshold must be a number (got: $2)"
                fi
                THRESHOLD_GB="$2"
                shift 2
                ;;
            --json)
                OUTPUT_FORMAT="json"
                shift
                ;;
            --report)
                if [[ -z "$2" || "$2" == --* ]]; then
                    die "--report requires a file path"
                fi
                REPORT_FILE="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            --verbose)
                VERBOSE="true"
                CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG
                shift
                ;;
            --modules)
                if [[ -z "$2" || "$2" == --* ]]; then
                    die "--modules requires a comma-separated list of modules"
                fi
                SELECTED_MODULES="$2"
                shift 2
                ;;
            -*)
                die "Unknown option: $1. Use --help for usage information."
                ;;
            *)
                die "Unexpected argument: $1. Use --help for usage information."
                ;;
        esac
    done
}

# Check if a module should run
should_run_module() {
    local module_name="$1"

    # If no modules specified, run all
    if [[ -z "$SELECTED_MODULES" ]]; then
        return 0
    fi

    # Check if module is in the selected list
    IFS=',' read -ra modules <<< "$SELECTED_MODULES"
    for m in "${modules[@]}"; do
        if [[ "$(trim "$m")" == "$module_name" ]]; then
            return 0
        fi
    done

    return 1
}

# Validate selected modules
validate_modules() {
    if [[ -z "$SELECTED_MODULES" ]]; then
        return 0
    fi

    local valid_modules="disk memory processes directories bloat"
    IFS=',' read -ra modules <<< "$SELECTED_MODULES"

    for m in "${modules[@]}"; do
        local trimmed
        trimmed=$(trim "$m")
        if [[ ! " $valid_modules " =~ " $trimmed " ]]; then
            die "Unknown module: $trimmed. Valid modules: $valid_modules"
        fi
    done
}
