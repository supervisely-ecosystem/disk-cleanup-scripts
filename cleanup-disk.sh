#!/bin/bash

# Supervisely Disk Cleanup Script
# This script removes stopped sly-task containers and unused Docker images

echo "================================================"
echo "DISK CLEANUP SCRIPT"
echo "================================================"
echo ""

# Check if running with proper permissions
if [ "$EUID" -ne 0 ] && ! groups | grep -q docker; then
    echo "WARNING: This script should be run as root or with a user in the docker group"
    echo ""
fi

echo "Step 1: Removing stopped sly-task containers"
echo "----------------------------------------------"
STOPPED_CONTAINERS=$(docker ps -a -f "status=exited" -f "name=sly-task" -q)

if [ -z "$STOPPED_CONTAINERS" ]; then
    echo "No stopped sly-task containers found."
else
    CONTAINER_COUNT=$(echo "$STOPPED_CONTAINERS" | wc -l)
    echo "Found $CONTAINER_COUNT stopped sly-task container(s):"
    docker ps -a -f "status=exited" -f "name=sly-task" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    echo ""
    echo "Removing containers..."
    echo "$STOPPED_CONTAINERS" | xargs docker rm
    echo "✓ Removed $CONTAINER_COUNT stopped sly-task container(s)"
fi
echo ""

echo "Step 2: Pruning dangling images (not linked to containers)"
echo "------------------------------------------------------------"
echo "Checking for dangling images..."
DANGLING_IMAGES=$(docker images -f "dangling=true" -q)

if [ -z "$DANGLING_IMAGES" ]; then
    echo "No dangling images found."
else
    IMAGE_COUNT=$(echo "$DANGLING_IMAGES" | wc -l)
    echo "Found $IMAGE_COUNT dangling image(s)"
    echo ""
    echo "Removing dangling images..."
    docker image prune -f
    echo "✓ Removed dangling images"
fi
echo ""

echo "================================================"
echo "CLEANUP COMPLETE"
echo "================================================"
echo ""
echo "Space reclaimed summary:"
docker system df
echo ""
echo "Cleanup finished successfully!"
