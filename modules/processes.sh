#!/bin/bash
# Module: processes.sh
# Description: Heavy process detection

module_processes_name() {
    echo "Heavy Processes"
}

module_processes_description() {
    echo "Detects resource-intensive processes"
}

module_processes_run() {
    output_start_module "processes"
    output_section "$(module_processes_name)"

    # Get top CPU consumers
    local cpu_hogs
    cpu_hogs=$(ps -Aceo pid,pcpu,comm 2>/dev/null | sort -k2 -nr | head -6 | tail -5)

    if [[ -z "$cpu_hogs" ]]; then
        output_warning "Could not retrieve process information"
        output_section_end
        return 1
    fi

    output_item "Top CPU Consumers" ""

    local cpu_processes=()
    while IFS= read -r line; do
        local pid cpu comm
        read -r pid cpu comm <<< "$line"
        if [[ -n "$pid" && -n "$cpu" && -n "$comm" ]]; then
            output_table_row "$comm" "${cpu}% CPU" "PID: $pid"
            cpu_processes+=("$comm (${cpu}%)")

            # Warn about high CPU processes
            if (( $(echo "$cpu > 50" | bc -l 2>/dev/null || echo 0) )); then
                output_warning "Process '$comm' using ${cpu}% CPU"
            fi
        fi
    done <<< "$cpu_hogs"

    # JSON output for CPU processes
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        output_list "top_cpu_processes" "${cpu_processes[@]}"
    fi

    echo "${COLOR_CYAN}|${COLOR_RESET}"

    # Get top memory consumers
    local mem_hogs
    mem_hogs=$(ps -Aceo pid,pmem,comm 2>/dev/null | sort -k2 -nr | head -6 | tail -5)

    output_item "Top Memory Consumers" ""

    local mem_processes=()
    while IFS= read -r line; do
        local pid mem comm
        read -r pid mem comm <<< "$line"
        if [[ -n "$pid" && -n "$mem" && -n "$comm" ]]; then
            output_table_row "$comm" "${mem}% MEM" "PID: $pid"
            mem_processes+=("$comm (${mem}%)")

            # Warn about high memory processes
            if (( $(echo "$mem > 20" | bc -l 2>/dev/null || echo 0) )); then
                output_warning "Process '$comm' using ${mem}% memory"
            fi
        fi
    done <<< "$mem_hogs"

    # JSON output for memory processes
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        output_list "top_memory_processes" "${mem_processes[@]}"
    fi

    # Check for known resource-hungry dev processes
    local heavy_dev_procs="node java gradle webpack docker electron chrome firefox slack teams zoom"

    echo "${COLOR_CYAN}|${COLOR_RESET}"
    output_item "Dev Process Check" ""

    local found_heavy=false
    for proc in $heavy_dev_procs; do
        local count
        count=$(pgrep -f "$proc" 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$count" -gt 0 ]]; then
            output_table_row "$proc" "$count instance(s)"
            found_heavy=true
        fi
    done

    if [[ "$found_heavy" == "false" ]]; then
        output_table_row "No heavy dev processes" "detected"
    fi

    output_section_end
}
