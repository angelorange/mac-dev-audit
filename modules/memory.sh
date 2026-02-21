#!/bin/bash
# Module: memory.sh
# Description: Memory pressure & swap diagnostics

module_memory_name() {
    echo "Memory Usage"
}

module_memory_description() {
    echo "Analyzes memory pressure and swap usage"
}

module_memory_run() {
    output_start_module "memory"
    output_section "$(module_memory_name)"

    # Get memory info using vm_stat
    local vm_stat_output
    vm_stat_output=$(vm_stat 2>/dev/null)

    if [[ -z "$vm_stat_output" ]]; then
        output_warning "Could not retrieve memory information"
        output_section_end
        return 1
    fi

    # Parse vm_stat output
    local page_size
    page_size=$(pagesize 2>/dev/null || echo 4096)

    local pages_free pages_active pages_inactive pages_speculative pages_wired pages_compressed
    pages_free=$(echo "$vm_stat_output" | grep "Pages free" | awk '{print $3}' | tr -d '.')
    pages_active=$(echo "$vm_stat_output" | grep "Pages active" | awk '{print $3}' | tr -d '.')
    pages_inactive=$(echo "$vm_stat_output" | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
    pages_speculative=$(echo "$vm_stat_output" | grep "Pages speculative" | awk '{print $3}' | tr -d '.')
    pages_wired=$(echo "$vm_stat_output" | grep "Pages wired down" | awk '{print $4}' | tr -d '.')
    pages_compressed=$(echo "$vm_stat_output" | grep "Pages stored in compressor" | awk '{print $5}' | tr -d '.')

    # Calculate memory values in bytes
    local free_bytes=$((pages_free * page_size))
    local active_bytes=$((pages_active * page_size))
    local inactive_bytes=$((pages_inactive * page_size))
    local wired_bytes=$((pages_wired * page_size))
    local compressed_bytes=$((pages_compressed * page_size))

    # Get total physical memory
    local total_bytes
    total_bytes=$(sysctl -n hw.memsize 2>/dev/null)

    local used_bytes=$((total_bytes - free_bytes - inactive_bytes))
    local usage_percent=$((used_bytes * 100 / total_bytes))

    output_item "Total RAM" "$(bytes_to_human "$total_bytes")"
    output_item "Used" "$(bytes_to_human "$used_bytes")" "${usage_percent}%"
    output_item "Free" "$(bytes_to_human "$free_bytes")"
    output_item "Active" "$(bytes_to_human "$active_bytes")"
    output_item "Inactive" "$(bytes_to_human "$inactive_bytes")"
    output_item "Wired" "$(bytes_to_human "$wired_bytes")"
    output_item "Compressed" "$(bytes_to_human "$compressed_bytes")"

    # JSON-specific fields
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        _json_add_field "total_bytes" "$total_bytes"
        _json_add_field "used_bytes" "$used_bytes"
        _json_add_field "usage_percent" "$usage_percent"
    fi

    # Check swap usage
    local swap_info
    swap_info=$(sysctl -n vm.swapusage 2>/dev/null)

    if [[ -n "$swap_info" ]]; then
        local swap_total swap_used swap_free
        swap_total=$(echo "$swap_info" | awk '{print $3}' | tr -d 'M')
        swap_used=$(echo "$swap_info" | awk '{print $6}' | tr -d 'M')
        swap_free=$(echo "$swap_info" | awk '{print $9}' | tr -d 'M')

        output_item "Swap Total" "${swap_total}M"
        output_item "Swap Used" "${swap_used}M"

        if [[ "$OUTPUT_FORMAT" == "json" ]]; then
            _json_add_field "swap_total_mb" "$swap_total"
            _json_add_field "swap_used_mb" "$swap_used"
        fi

        # Warn if swap is heavily used
        if [[ "${swap_used%.*}" -gt 1024 ]]; then
            output_warning "High swap usage (${swap_used}M)"
            output_recommendation "Close unused applications to reduce memory pressure"
        fi
    fi

    # Check memory pressure
    local pressure
    if command_exists memory_pressure; then
        pressure=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage" | awk '{print $5}' | tr -d '%')
        if [[ -n "$pressure" && "$pressure" -lt 20 ]]; then
            output_warning "Low memory free percentage (${pressure}%)"
        fi
    fi

    output_section_end
}
