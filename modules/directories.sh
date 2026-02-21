#!/bin/bash
# Module: directories.sh
# Description: Large directory detection

module_directories_name() {
    echo "Large Directories"
}

module_directories_description() {
    echo "Finds directories exceeding the size threshold"
}

module_directories_run() {
    output_start_module "directories"
    output_section "$(module_directories_name)"

    local threshold_bytes
    threshold_bytes=$(gb_to_bytes "$THRESHOLD_GB")

    output_item "Threshold" "${THRESHOLD_GB} GB"

    # Common directories to check
    local dirs_to_check=(
        "$HOME/Library/Caches"
        "$HOME/Library/Application Support"
        "$HOME/Library/Logs"
        "$HOME/Library/Developer"
        "$HOME/Library/Containers"
        "$HOME/.cache"
        "$HOME/.local"
        "$HOME/.npm"
        "$HOME/.cargo"
        "$HOME/.rustup"
        "$HOME/.gradle"
        "$HOME/.m2"
        "$HOME/.nuget"
        "$HOME/.docker"
        "/usr/local/Cellar"
        "/opt/homebrew/Cellar"
    )

    local large_dirs=()
    local total_large_size=0

    echo "${COLOR_CYAN}|${COLOR_RESET}"
    output_item "Scanning" "common cache and development directories..."

    for dir in "${dirs_to_check[@]}"; do
        if [[ -d "$dir" ]]; then
            # Get directory size (BSD du uses -sk for KB)
            local size_kb
            size_kb=$(du -sk "$dir" 2>/dev/null | cut -f1)

            if [[ -n "$size_kb" ]]; then
                local size_bytes=$((size_kb * 1024))

                if [[ "$size_bytes" -ge "$threshold_bytes" ]]; then
                    local size_human
                    size_human=$(bytes_to_human "$size_bytes")
                    output_table_row "$dir" "$size_human"
                    large_dirs+=("$dir ($size_human)")
                    total_large_size=$((total_large_size + size_bytes))
                fi
            fi
        fi
    done

    if [[ ${#large_dirs[@]} -eq 0 ]]; then
        output_item "Result" "No directories exceed ${THRESHOLD_GB} GB threshold"
    else
        echo "${COLOR_CYAN}|${COLOR_RESET}"
        output_item "Found" "${#large_dirs[@]} large directories"
        output_item "Combined Size" "$(bytes_to_human "$total_large_size")"

        if [[ "$OUTPUT_FORMAT" == "json" ]]; then
            output_list "large_directories" "${large_dirs[@]}"
            _json_add_field "total_large_bytes" "$total_large_size"
            _json_add_field "count" "${#large_dirs[@]}"
        fi

        output_recommendation "Review large directories for cleanup opportunities"
    fi

    # Check user home directory breakdown
    echo "${COLOR_CYAN}|${COLOR_RESET}"
    output_item "Home Directory Breakdown" ""

    local home_subdirs
    home_subdirs=$(du -sk "$HOME"/* "$HOME"/.[!.]* 2>/dev/null | sort -rn | head -5)

    while IFS= read -r line; do
        local size_kb path
        read -r size_kb path <<< "$line"
        if [[ -n "$size_kb" && -n "$path" ]]; then
            local size_bytes=$((size_kb * 1024))
            local size_human
            size_human=$(bytes_to_human "$size_bytes")
            local basename
            basename=$(basename "$path")
            output_table_row "$basename" "$size_human"
        fi
    done <<< "$home_subdirs"

    output_section_end
}
