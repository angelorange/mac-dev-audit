#!/bin/bash
# Output formatting (human/JSON/report)
# Compatible with bash 3.2+ (macOS default)

# JSON accumulator - using temp files for bash 3.2 compatibility
JSON_TEMP_DIR=""
JSON_WARNINGS="[]"
JSON_RECOMMENDATIONS="[]"

# Current module being processed
CURRENT_MODULE=""

# Initialize output
output_init() {
    JSON_WARNINGS="[]"
    JSON_RECOMMENDATIONS="[]"

    # Create temp directory for JSON data
    JSON_TEMP_DIR=$(mktemp -d -t "mac-dev-audit-json.XXXXXX")
}

# Cleanup JSON temp directory
output_cleanup() {
    if [[ -n "$JSON_TEMP_DIR" && -d "$JSON_TEMP_DIR" ]]; then
        rm -rf "$JSON_TEMP_DIR"
    fi
}

# Start a new module section
output_start_module() {
    CURRENT_MODULE="$1"

    if [[ "$OUTPUT_FORMAT" == "human" ]]; then
        return 0
    fi

    # Initialize module JSON file
    if [[ -n "$JSON_TEMP_DIR" ]]; then
        echo -n "" > "$JSON_TEMP_DIR/$CURRENT_MODULE.json"
    fi
}

# Output section header
output_section() {
    local title="$1"

    if [[ "$OUTPUT_FORMAT" == "human" ]]; then
        echo ""
        echo "${COLOR_CYAN}${COLOR_BOLD}+-- $title $(printf '%*s' $((60 - ${#title})) '' | tr ' ' '-')${COLOR_RESET}"
        echo "${COLOR_CYAN}|${COLOR_RESET}"
    fi
}

# Output a key-value item
output_item() {
    local key="$1"
    local value="$2"
    local explanation="${3:-}"

    if [[ "$OUTPUT_FORMAT" == "human" ]]; then
        if [[ -n "$explanation" ]]; then
            printf "${COLOR_CYAN}|${COLOR_RESET}  %-20s %s ${COLOR_DIM}(%s)${COLOR_RESET}\n" "$key:" "$value" "$explanation"
        else
            printf "${COLOR_CYAN}|${COLOR_RESET}  %-20s %s\n" "$key:" "$value"
        fi
    else
        # Append to module JSON
        local json_key
        json_key=$(echo "$key" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
        _json_add_field "$json_key" "$value"
    fi
}

# Output a warning
output_warning() {
    local message="$1"

    if [[ "$OUTPUT_FORMAT" == "human" ]]; then
        echo "${COLOR_CYAN}|${COLOR_RESET}"
        echo "${COLOR_CYAN}|${COLOR_RESET}  ${COLOR_YELLOW}! Warning:${COLOR_RESET} $message"
    else
        _json_add_warning "$message"
    fi
}

# Output a recommendation
output_recommendation() {
    local action="$1"
    local reason="${2:-}"

    if [[ "$OUTPUT_FORMAT" == "human" ]]; then
        if [[ -n "$reason" ]]; then
            echo "${COLOR_CYAN}|${COLOR_RESET}  ${COLOR_GREEN}> Recommendation:${COLOR_RESET} $action"
            echo "${COLOR_CYAN}|${COLOR_RESET}    ${COLOR_DIM}Reason: $reason${COLOR_RESET}"
        else
            echo "${COLOR_CYAN}|${COLOR_RESET}  ${COLOR_GREEN}> Recommendation:${COLOR_RESET} $action"
        fi
    else
        _json_add_recommendation "$action" "$reason"
    fi
}

# Output a list of items
output_list() {
    local title="$1"
    shift

    if [[ "$OUTPUT_FORMAT" == "human" ]]; then
        echo "${COLOR_CYAN}|${COLOR_RESET}"
        echo "${COLOR_CYAN}|${COLOR_RESET}  ${COLOR_BOLD}$title:${COLOR_RESET}"
        for item in "$@"; do
            echo "${COLOR_CYAN}|${COLOR_RESET}    - $item"
        done
    else
        local json_key
        json_key=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
        local json_array="["
        local first=true
        for item in "$@"; do
            if [[ "$first" == "true" ]]; then
                first=false
            else
                json_array+=","
            fi
            json_array+="\"$(echo "$item" | sed 's/"/\\"/g')\""
        done
        json_array+="]"
        _json_add_field_raw "$json_key" "$json_array"
    fi
}

# Output table row
output_table_row() {
    local col1="$1"
    local col2="$2"
    local col3="${3:-}"

    if [[ "$OUTPUT_FORMAT" == "human" ]]; then
        if [[ -n "$col3" ]]; then
            printf "${COLOR_CYAN}|${COLOR_RESET}    %-30s %-15s %s\n" "$col1" "$col2" "$col3"
        else
            printf "${COLOR_CYAN}|${COLOR_RESET}    %-30s %s\n" "$col1" "$col2"
        fi
    fi
}

# End section
output_section_end() {
    if [[ "$OUTPUT_FORMAT" == "human" ]]; then
        echo "${COLOR_CYAN}|${COLOR_RESET}"
        echo "${COLOR_CYAN}+$(printf '%*s' 65 '' | tr ' ' '-')${COLOR_RESET}"
    fi
}

# Print header banner
output_header() {
    if [[ "$OUTPUT_FORMAT" == "human" ]]; then
        echo ""
        echo "${COLOR_CYAN}${COLOR_BOLD}+==================================================================+${COLOR_RESET}"
        echo "${COLOR_CYAN}${COLOR_BOLD}|                    macOS Dev Audit Tool                         |${COLOR_RESET}"
        echo "${COLOR_CYAN}${COLOR_BOLD}|                        v$VERSION                                  |${COLOR_RESET}"
        echo "${COLOR_CYAN}${COLOR_BOLD}+==================================================================+${COLOR_RESET}"
        echo ""
        echo "  ${COLOR_DIM}Running on: macOS $(get_macos_version)${COLOR_RESET}"
        echo "  ${COLOR_DIM}Timestamp:  $(date '+%Y-%m-%d %H:%M:%S')${COLOR_RESET}"
    fi
}

# Print footer
output_footer() {
    if [[ "$OUTPUT_FORMAT" == "human" ]]; then
        echo ""
        echo "${COLOR_DIM}Audit complete. No files were modified.${COLOR_RESET}"
        echo ""
    fi
}

# JSON helper: add a field to current module
_json_add_field() {
    local key="$1"
    local value="$2"

    # Try to detect if value is numeric
    if [[ "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        _json_add_field_raw "$key" "$value"
    else
        _json_add_field_raw "$key" "\"$(echo "$value" | sed 's/"/\\"/g')\""
    fi
}

_json_add_field_raw() {
    local key="$1"
    local value="$2"

    if [[ -z "$JSON_TEMP_DIR" || -z "$CURRENT_MODULE" ]]; then
        return
    fi

    local json_file="$JSON_TEMP_DIR/$CURRENT_MODULE.json"

    if [[ -s "$json_file" ]]; then
        echo -n ",\"$key\":$value" >> "$json_file"
    else
        echo -n "\"$key\":$value" >> "$json_file"
    fi
}

_json_add_warning() {
    local message="$1"
    local escaped
    escaped=$(echo "$message" | sed 's/"/\\"/g')

    if [[ "$JSON_WARNINGS" == "[]" ]]; then
        JSON_WARNINGS="[\"$escaped\"]"
    else
        JSON_WARNINGS="${JSON_WARNINGS%]},\"$escaped\"]"
    fi
}

_json_add_recommendation() {
    local action="$1"
    local reason="$2"
    local escaped_action
    local escaped_reason
    escaped_action=$(echo "$action" | sed 's/"/\\"/g')
    escaped_reason=$(echo "$reason" | sed 's/"/\\"/g')

    local rec="{\"action\":\"$escaped_action\""
    if [[ -n "$reason" ]]; then
        rec+=",\"reason\":\"$escaped_reason\""
    fi
    rec+="}"

    if [[ "$JSON_RECOMMENDATIONS" == "[]" ]]; then
        JSON_RECOMMENDATIONS="[$rec]"
    else
        JSON_RECOMMENDATIONS="${JSON_RECOMMENDATIONS%]},$rec]"
    fi
}

# Finalize and output JSON
output_json_final() {
    local timestamp
    timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    echo "{"
    echo "  \"version\": \"$VERSION\","
    echo "  \"timestamp\": \"$timestamp\","
    echo "  \"macos_version\": \"$(get_macos_version)\","
    echo "  \"modules\": {"

    local first=true
    if [[ -n "$JSON_TEMP_DIR" && -d "$JSON_TEMP_DIR" ]]; then
        for json_file in "$JSON_TEMP_DIR"/*.json; do
            if [[ -f "$json_file" ]]; then
                local module_name
                module_name=$(basename "$json_file" .json)
                local module_data
                module_data=$(cat "$json_file")

                if [[ "$first" == "true" ]]; then
                    first=false
                else
                    echo ","
                fi
                echo -n "    \"$module_name\": {$module_data}"
            fi
        done
    fi

    echo ""
    echo "  },"
    echo "  \"warnings\": $JSON_WARNINGS,"
    echo "  \"recommendations\": $JSON_RECOMMENDATIONS"
    echo "}"

    # Cleanup temp dir
    output_cleanup
}

# Write output to report file
output_to_report() {
    local file="$1"
    local content="$2"

    # Create directory if needed
    local dir
    dir=$(dirname "$file")
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || die "Cannot create directory: $dir"
    fi

    echo "$content" > "$file" || die "Cannot write to: $file"
    log_info "Report written to: $file"
}
