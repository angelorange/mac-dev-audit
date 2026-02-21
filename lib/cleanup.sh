#!/bin/bash
# Cleanup utilities - interactive and safe deletion
# Compatible with bash 3.2+ (macOS default)

# Cleanup mode flags
CLEAN_MODE="${CLEAN_MODE:-false}"
DRY_RUN="${DRY_RUN:-false}"

# Track what will be / was deleted
CLEANUP_ITEMS=""
CLEANUP_TOTAL_BYTES=0

# Add item to cleanup list
cleanup_add_item() {
    local path="$1"
    local size_bytes="$2"
    local category="$3"

    CLEANUP_ITEMS="${CLEANUP_ITEMS}${path}|${size_bytes}|${category}
"
    CLEANUP_TOTAL_BYTES=$((CLEANUP_TOTAL_BYTES + size_bytes))
}

# Show cleanup preview
cleanup_show_preview() {
    if [[ -z "$CLEANUP_ITEMS" ]]; then
        echo ""
        echo "${COLOR_YELLOW}No items found for cleanup.${COLOR_RESET}"
        return 1
    fi

    echo ""
    echo "${COLOR_BOLD}${COLOR_CYAN}=== Cleanup Preview ===${COLOR_RESET}"
    echo ""

    local count=0
    echo "$CLEANUP_ITEMS" | while IFS='|' read -r path size_bytes category; do
        [[ -z "$path" ]] && continue
        local size_human
        size_human=$(bytes_to_human "$size_bytes")
        printf "  ${COLOR_RED}[DELETE]${COLOR_RESET} %-50s %10s  ${COLOR_DIM}(%s)${COLOR_RESET}\n" "$path" "$size_human" "$category"
        count=$((count + 1))
    done

    echo ""
    echo "${COLOR_BOLD}Total to free: $(bytes_to_human "$CLEANUP_TOTAL_BYTES")${COLOR_RESET}"
    echo ""
}

# Prompt for confirmation
cleanup_confirm() {
    local message="${1:-Are you sure you want to delete these items?}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "${COLOR_YELLOW}[DRY-RUN] Would delete the items above.${COLOR_RESET}"
        return 1
    fi

    echo -n "${COLOR_YELLOW}${message} [y/N]: ${COLOR_RESET}"
    read -r response

    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            echo "${COLOR_DIM}Cleanup cancelled.${COLOR_RESET}"
            return 1
            ;;
    esac
}

# Perform cleanup
cleanup_execute() {
    if [[ -z "$CLEANUP_ITEMS" ]]; then
        return 0
    fi

    local deleted_count=0
    local deleted_bytes=0
    local failed_count=0

    echo ""
    echo "${COLOR_BOLD}Cleaning up...${COLOR_RESET}"
    echo ""

    echo "$CLEANUP_ITEMS" | while IFS='|' read -r path size_bytes category; do
        [[ -z "$path" ]] && continue

        if [[ -e "$path" ]]; then
            local size_human
            size_human=$(bytes_to_human "$size_bytes")

            echo -n "  Deleting $path... "

            if rm -rf "$path" 2>/dev/null; then
                echo "${COLOR_GREEN}done${COLOR_RESET} (freed $size_human)"
                deleted_count=$((deleted_count + 1))
                deleted_bytes=$((deleted_bytes + size_bytes))
            else
                echo "${COLOR_RED}failed${COLOR_RESET}"
                failed_count=$((failed_count + 1))
            fi
        fi
    done

    echo ""
    echo "${COLOR_GREEN}Cleanup complete!${COLOR_RESET}"
    echo "  Items deleted: $deleted_count"
    echo "  Space freed: $(bytes_to_human "$deleted_bytes")"

    if [[ $failed_count -gt 0 ]]; then
        echo "  ${COLOR_RED}Failed: $failed_count${COLOR_RESET}"
    fi
}

# Interactive cleanup for a single item
cleanup_prompt_single() {
    local path="$1"
    local size_human="$2"
    local category="$3"

    echo ""
    echo "${COLOR_BOLD}Found:${COLOR_RESET} $path"
    echo "  Size: $size_human"
    echo "  Type: $category"
    echo ""
    echo -n "  Delete this? [y/N/a(ll)/q(uit)]: "
    read -r response

    case "$response" in
        [yY])
            return 0  # Delete this one
            ;;
        [aA])
            return 2  # Delete all remaining
            ;;
        [qQ])
            return 3  # Quit cleanup
            ;;
        *)
            return 1  # Skip
            ;;
    esac
}

# Safe patterns that are OK to delete
is_safe_to_delete() {
    local path="$1"

    # Never delete these
    local forbidden_patterns=(
        "$HOME/Documents"
        "$HOME/Desktop"
        "$HOME/Downloads"
        "$HOME/Pictures"
        "$HOME/Movies"
        "$HOME/Music"
        "$HOME/.ssh"
        "$HOME/.gnupg"
        "/System"
        "/Library"
        "/Applications"
        "/Users"
        "/bin"
        "/sbin"
        "/usr"
        "/var"
        "/etc"
        "/private"
    )

    for pattern in "${forbidden_patterns[@]}"; do
        if [[ "$path" == "$pattern" || "$path" == "$pattern/"* ]]; then
            # Exception: allow Library/Caches subdirectories
            if [[ "$path" == "$HOME/Library/Caches/"* && "$path" != "$HOME/Library/Caches" ]]; then
                continue
            fi
            return 1
        fi
    done

    # Safe patterns to delete
    local safe_patterns=(
        "node_modules"
        ".gradle"
        "DerivedData"
        "__pycache__"
        ".cache"
        "target"
        "build"
        "dist"
        ".npm"
        ".cargo/registry"
        "Pods"
        ".pnpm-store"
        ".nuget"
        "vendor"
        ".venv"
        "venv"
    )

    local basename
    basename=$(basename "$path")

    for pattern in "${safe_patterns[@]}"; do
        if [[ "$basename" == "$pattern" ]]; then
            return 0
        fi
    done

    # Cache directories are generally safe
    if [[ "$path" == *"/Caches/"* || "$path" == *"/.cache/"* ]]; then
        return 0
    fi

    # Unknown pattern - not safe by default
    return 1
}

# Reset cleanup state
cleanup_reset() {
    CLEANUP_ITEMS=""
    CLEANUP_TOTAL_BYTES=0
}
