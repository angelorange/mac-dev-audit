#!/bin/bash

THRESHOLD_GB=1

echo "========================================="
echo "        macOS Dev Audit Tool"
echo "========================================="
echo ""

# -----------------------------------------
# Disk Overview
# -----------------------------------------
echo "---- Disk Overview ----"
df -h /
echo ""

# -----------------------------------------
# Memory Overview
# -----------------------------------------
echo "---- Memory Overview ----"
sysctl vm.swapusage
echo ""
vm_stat | head -10
echo ""

# -----------------------------------------
# Top Memory Consumers
# -----------------------------------------
echo "---- Top Memory Consuming Applications ----"
ps aux | awk '{print $11, $4}' | \
grep -v COMMAND | \
awk '{usage[$1]+=$2} END {for (app in usage) print usage[app], app}' | \
sort -nr | head -10
echo ""

# -----------------------------------------
# Large Directories in Home (>1GB)
# -----------------------------------------
echo "---- Large Directories in Home (> ${THRESHOLD_GB}GB) ----"
du -sh ~/* 2>/dev/null | \
awk -v threshold="${THRESHOLD_GB}G" '
function human_to_gb(size) {
    if (size ~ /G/) return substr(size, 1, length(size)-1)
    if (size ~ /M/) return substr(size, 1, length(size)-1) / 1024
    return 0
}
{
    size=$1
    gb=human_to_gb(size)
    if (gb >= '"$THRESHOLD_GB"') print $0
}'
echo ""

# -----------------------------------------
# Large Hidden Directories (~/.something)
# -----------------------------------------
echo "---- Large Hidden Directories (> ${THRESHOLD_GB}GB) ----"
du -sh ~/.* 2>/dev/null | \
grep -v "/\.\.$" | \
grep -v "/\.$" | \
sort -hr | head -10
echo ""

# -----------------------------------------
# Build / Dependency Pattern Detection
# -----------------------------------------
echo "---- Large Build/Dependency Directories ----"
find ~ -type d \( \
-name "node_modules" -o \
-name "build" -o \
-name "dist" -o \
-name ".gradle" -o \
-name ".cache" -o \
-name "DerivedData" \
\) 2>/dev/null | while read dir; do
    size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
    echo "$size  $dir"
done | sort -hr | head -15

echo ""

echo "========================================="
echo "        Audit Complete"
echo "========================================="
