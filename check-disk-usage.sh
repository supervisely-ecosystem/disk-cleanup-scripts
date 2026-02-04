#!/bin/bash

# Supervisely Disk Usage Check Script
# This script analyzes disk usage and Docker resource consumption

# Detect if sudo is needed for docker commands
DOCKER_CMD="docker"
if ! docker ps >/dev/null 2>&1; then
    if sudo docker ps >/dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
        echo "Note: Using 'sudo' for Docker commands"
        echo ""
    fi
fi

echo "================================================"
echo "DISK USAGE ANALYSIS"
echo "================================================"
echo ""

echo "Top 10 directories by size:"
echo "----------------------------"
du -h --max-depth=2 / 2>/dev/null | sort -rh | head -20 | grep -v "Permission denied"
echo ""

echo "================================================"
echo "DOCKER RESOURCE USAGE"
echo "================================================"
echo ""

echo "Overall Docker disk usage:"
echo "----------------------------"
$DOCKER_CMD system df
echo ""

echo "Detailed Docker disk usage:"
echo "----------------------------"
$DOCKER_CMD system df -v
echo ""

echo "================================================"
echo "DOCKER IMAGES ANALYSIS"
echo "================================================"
echo ""

echo "Space occupied by dangling images (not linked to containers):"
echo "---------------------------------------------------------------"
DANGLING_SIZE=$($DOCKER_CMD images -f "dangling=true" -q | xargs -r $DOCKER_CMD inspect --format='{{.Size}}' 2>/dev/null | awk '{sum+=$1} END {print sum/1024/1024/1024}')
if [ -z "$DANGLING_SIZE" ]; then
    echo "0 GB"
else
    echo "${DANGLING_SIZE} GB"
fi
echo ""

echo "List of dangling images:"
$DOCKER_CMD images -f "dangling=true"
echo ""

echo "================================================"
echo "STOPPED SLY-TASK CONTAINERS"
echo "================================================"
echo ""

STOPPED_COUNT=$($DOCKER_CMD ps -a -f "status=exited" -f "name=sly-task" --format "{{.Names}}" | wc -l)
echo "Number of stopped sly-task containers: $STOPPED_COUNT"
echo ""

if [ $STOPPED_COUNT -gt 0 ]; then
    echo "List of stopped sly-task containers:"
    echo "-------------------------------------"
    $DOCKER_CMD ps -a -f "status=exited" -f "name=sly-task" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Size}}"
fi
echo ""

echo "================================================"
echo "SUMMARY"
echo "================================================"
echo "Total stopped sly-task containers: $STOPPED_COUNT"
echo "Dangling images size: ${DANGLING_SIZE:-0} GB"
echo "================================================"
