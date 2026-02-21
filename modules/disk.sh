#!/bin/bash
# Module: disk.sh
# Description: Disk usage diagnostics

module_disk_name() {
    echo "Disk Usage"
}

module_disk_description() {
    echo "Analyzes disk space usage and availability"
}

module_disk_run() {
    output_start_module "disk"
    output_section "$(module_disk_name)"

    # Get disk info using df
    local disk_info
    disk_info=$(df -H / 2>/dev/null | tail -1)

    if [[ -z "$disk_info" ]]; then
        output_warning "Could not retrieve disk information"
        output_section_end
        return 1
    fi

    # Parse df output (BSD format)
    local total used available capacity
    read -r _ total used available capacity _ <<< "$disk_info"

    # Remove % from capacity
    local usage_percent="${capacity%\%}"

    output_item "Total" "$total"
    output_item "Used" "$used" "${usage_percent}%"
    output_item "Available" "$available"

    # JSON-specific fields
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        _json_add_field "usage_percent" "$usage_percent"
    fi

    # Warnings based on usage
    if [[ "$usage_percent" -ge 90 ]]; then
        output_warning "Disk usage critical (${usage_percent}%)"
        output_recommendation "Free up disk space immediately" "System may become unstable below 5% free space"
    elif [[ "$usage_percent" -ge 75 ]]; then
        output_warning "Disk usage above 75%"
        output_recommendation "Consider freeing up space to maintain system performance"
    fi

    # Check for APFS snapshots taking space
    local snapshots
    if command_exists tmutil; then
        snapshots=$(tmutil listlocalsnapshots / 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$snapshots" -gt 5 ]]; then
            output_item "Local Snapshots" "$snapshots"
            output_recommendation "Run 'tmutil thinlocalsnapshots / 10000000000 1' to free snapshot space"
        fi
    fi

    output_section_end
}
