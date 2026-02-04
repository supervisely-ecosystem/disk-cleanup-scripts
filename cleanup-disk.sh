#!/bin/bash

# Supervisely Disk Cleanup Script
# This script removes stopped sly-task containers and unused Docker images

# Detect if sudo is needed for docker commands
DOCKER_CMD="docker"
if ! docker ps >/dev/null 2>&1; then
    if sudo docker ps >/dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
        echo "Note: Using 'sudo' for Docker commands"
        echo ""
    else
        echo "ERROR: Cannot access Docker. Please ensure Docker is installed and you have proper permissions."
        exit 1
    fi
fi

echo "================================================"
echo "DISK CLEANUP SCRIPT"
echo "================================================"
echo ""

echo "Step 1: Removing stopped sly-task containers"
echo "----------------------------------------------"
STOPPED_CONTAINERS=$($DOCKER_CMD ps -a -f "status=exited" -f "name=sly-task" -q)

if [ -z "$STOPPED_CONTAINERS" ]; then
    echo "No stopped sly-task containers found."
else
    CONTAINER_COUNT=$(echo "$STOPPED_CONTAINERS" | wc -l)
    echo "Found $CONTAINER_COUNT stopped sly-task container(s):"
    $DOCKER_CMD ps -a -f "status=exited" -f "name=sly-task" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    echo ""
    echo "Removing containers..."
    echo "$STOPPED_CONTAINERS" | xargs $DOCKER_CMD rm
    echo "✓ Removed $CONTAINER_COUNT stopped sly-task container(s)"
fi
echo ""

echo "Step 2: Pruning dangling images (not linked to containers)"
echo "------------------------------------------------------------"
echo "Checking for dangling images..."
DANGLING_IMAGES=$($DOCKER_CMD images -f "dangling=true" -q)

if [ -z "$DANGLING_IMAGES" ]; then
    echo "No dangling images found."
else
    IMAGE_COUNT=$(echo "$DANGLING_IMAGES" | wc -l)
    echo "Found $IMAGE_COUNT dangling image(s)"
    echo ""
    echo "Removing dangling images..."
    $DOCKER_CMD image prune -f
    echo "✓ Removed dangling images"
fi
echo ""

echo "================================================"
echo "CLEANUP COMPLETE"
echo "================================================"
echo ""
echo "Space reclaimed summary:"
$DOCKER_CMD system df
echo ""
echo "Cleanup finished successfully!"
