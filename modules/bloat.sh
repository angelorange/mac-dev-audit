#!/bin/bash
# Module: bloat.sh
# Description: Dev bloat pattern detection
# Compatible with bash 3.2+ (macOS default)

module_bloat_name() {
    echo "Development Bloat"
}

module_bloat_description() {
    echo "Detects common development cache and build artifacts"
}

module_bloat_run() {
    output_start_module "bloat"
    output_section "$(module_bloat_name)"

    local script_dir
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

    # Get patterns from file
    local patterns
    patterns=$(get_bloat_patterns "$script_dir")

    if [[ -z "$patterns" ]]; then
        output_warning "No bloat patterns file found"
        output_section_end
        return 1
    fi

    output_item "Scanning" "home directory for development bloat..."

    local threshold_bytes
    threshold_bytes=$(gb_to_bytes "$THRESHOLD_GB")

    # Track findings using temp files for bash 3.2 compatibility
    local bloat_temp_dir
    bloat_temp_dir=$(mktemp -d -t "mac-dev-audit-bloat.XXXXXX")

    local total_bloat_size=0
    local bloat_items_file="$bloat_temp_dir/items.txt"
    touch "$bloat_items_file"

    # Category tracking files
    local cat_dependencies=0
    local cat_build_cache=0
    local cat_build_output=0
    local cat_cache=0
    local cat_package_manager=0

    # Process each pattern
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        local pattern category explanation
        pattern=$(parse_bloat_pattern "$line" 1)
        category=$(parse_bloat_pattern "$line" 2)
        explanation=$(parse_bloat_pattern "$line" 3)

        [[ -z "$pattern" ]] && continue

        # Search for pattern in home directory (max depth 5 for performance)
        while IFS= read -r found_path; do
            if [[ -d "$found_path" ]]; then
                local size_kb
                size_kb=$(du -sk "$found_path" 2>/dev/null | cut -f1)

                if [[ -n "$size_kb" ]]; then
                    local size_bytes=$((size_kb * 1024))

                    # Only report if significant size (> 100MB)
                    if [[ "$size_bytes" -gt 104857600 ]]; then
                        local size_human
                        size_human=$(bytes_to_human "$size_bytes")

                        total_bloat_size=$((total_bloat_size + size_bytes))

                        # Track by category
                        case "$category" in
                            dependencies)
                                cat_dependencies=$((cat_dependencies + size_bytes))
                                ;;
                            build-cache)
                                cat_build_cache=$((cat_build_cache + size_bytes))
                                ;;
                            build-output)
                                cat_build_output=$((cat_build_output + size_bytes))
                                ;;
                            cache)
                                cat_cache=$((cat_cache + size_bytes))
                                ;;
                            package-manager)
                                cat_package_manager=$((cat_package_manager + size_bytes))
                                ;;
                        esac

                        echo "$size_bytes|$found_path|$size_human|$category" >> "$bloat_items_file"

                        if [[ "$VERBOSE" == "true" ]]; then
                            output_table_row "$found_path" "$size_human" "$category"
                        fi
                    fi
                fi
            fi
        done < <(find "$HOME" -maxdepth 5 -type d -name "$pattern" 2>/dev/null)

    done <<< "$patterns"

    # Output summary by category
    echo "${COLOR_CYAN}|${COLOR_RESET}"
    output_item "Bloat by Category" ""

    if [[ "$cat_dependencies" -gt 0 ]]; then
        output_table_row "dependencies" "$(bytes_to_human "$cat_dependencies")"
    fi
    if [[ "$cat_build_cache" -gt 0 ]]; then
        output_table_row "build-cache" "$(bytes_to_human "$cat_build_cache")"
    fi
    if [[ "$cat_build_output" -gt 0 ]]; then
        output_table_row "build-output" "$(bytes_to_human "$cat_build_output")"
    fi
    if [[ "$cat_cache" -gt 0 ]]; then
        output_table_row "cache" "$(bytes_to_human "$cat_cache")"
    fi
    if [[ "$cat_package_manager" -gt 0 ]]; then
        output_table_row "package-manager" "$(bytes_to_human "$cat_package_manager")"
    fi

    echo "${COLOR_CYAN}|${COLOR_RESET}"
    output_item "Total Bloat Found" "$(bytes_to_human "$total_bloat_size")"

    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        _json_add_field "total_bloat_bytes" "$total_bloat_size"

        # Add category breakdown
        local cat_json="{"
        cat_json+="\"dependencies\":$cat_dependencies"
        cat_json+=",\"build-cache\":$cat_build_cache"
        cat_json+=",\"build-output\":$cat_build_output"
        cat_json+=",\"cache\":$cat_cache"
        cat_json+=",\"package-manager\":$cat_package_manager"
        cat_json+="}"
        _json_add_field_raw "categories" "$cat_json"
    fi

    # Recommendations
    if [[ "$total_bloat_size" -gt "$threshold_bytes" ]]; then
        output_warning "Development bloat exceeds ${THRESHOLD_GB} GB threshold"

        if [[ "$cat_dependencies" -gt 0 ]]; then
            output_recommendation "Run 'npm cache clean --force' or equivalent for your package manager"
        fi

        if [[ "$cat_build_cache" -gt 0 ]]; then
            output_recommendation "Clear build caches in unused projects"
        fi

        if [[ "$cat_cache" -gt 0 ]]; then
            output_recommendation "Review and clear old cache directories"
        fi
    fi

    # List top bloat items
    if [[ -s "$bloat_items_file" ]]; then
        echo "${COLOR_CYAN}|${COLOR_RESET}"
        output_item "Largest Bloat Items" "(top 10)"

        # Sort by size (first field) and show top 10
        local count=0
        sort -t'|' -k1 -rn "$bloat_items_file" | head -10 | while IFS='|' read -r size_bytes path size_human category; do
            output_table_row "$(basename "$(dirname "$path")")/$(basename "$path")" "$size_human" "$category"
        done
    fi

    # Cleanup
    rm -rf "$bloat_temp_dir"

    output_section_end
}
