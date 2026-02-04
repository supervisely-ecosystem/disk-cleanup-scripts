# Supervisely Disk Cleanup Utilities

This package contains two shell scripts for monitoring and cleaning up disk space on Supervisely servers.

## Scripts Overview

### 1. `check-disk-usage.sh` - Disk Usage Analysis Script

This script provides a comprehensive overview of disk and Docker resource usage without making any changes.

**What it shows:**
- Top 20 directories by size on the system
- Overall Docker disk usage (images, containers, volumes)
- Detailed breakdown of Docker resources
- Space occupied by dangling images (not linked to any containers)
- List of all dangling images
- Number and list of stopped containers with "sly-task" in their name

**Usage:**
```bash
bash check-disk-usage.sh
```

### 2. `cleanup-disk.sh` - Disk Cleanup Script

This script performs actual cleanup operations to free up disk space.

**What it does:**
- Removes all stopped containers that contain "sly-task" in their name
- Prunes dangling Docker images (images not linked to any containers)
- Shows a summary of space reclaimed

**Usage:**
```bash
bash cleanup-disk.sh
```

**⚠️ WARNING:** This script will permanently delete stopped containers and unused images. Always run `check-disk-usage.sh` first to review what will be removed.

---

## Installation Instructions

### Option 1: Upload Files Using SCP

From your local machine, upload the scripts to the server:

```bash
# Upload both scripts to the server
scp check-disk-usage.sh cleanup-disk.sh user@server-ip:/home/user/

# Upload to a specific directory
scp check-disk-usage.sh cleanup-disk.sh user@server-ip:/opt/supervisely/scripts/
```

Replace:
- `user` with your SSH username
- `server-ip` with your server's IP address or hostname
- `/home/user/` with your desired destination path

### Option 2: Upload Using SFTP

```bash
sftp user@server-ip
put check-disk-usage.sh
put cleanup-disk.sh
bye
```

### Make Scripts Executable

After uploading, SSH into the server and make the scripts executable:

```bash
ssh user@server-ip
chmod +x check-disk-usage.sh cleanup-disk.sh
```

---

## Recommended Workflow

### Step 1: Check Current Usage

Always start by analyzing the current disk usage:

```bash
bash check-disk-usage.sh
```

Review the output carefully to understand:
- Which directories are consuming the most space
- How much space Docker is using
- How many stopped sly-task containers exist
- How much space can be reclaimed from dangling images

### Step 2: Clean Heaviest Directories (Manual)

Before deleting any directories, **always check for sensitive data first!**

#### Common directories to check:

**Log files:**
```bash
# Check size
du -sh /var/log/

# Check for sensitive data (review output carefully)
ls -lh /var/log/

# Clean old logs (only after verification!)
sudo find /var/log -type f -name "*.log" -mtime +30 -delete
```

**Temporary files:**
```bash
# Check size
du -sh /tmp/

# Clean old temp files (older than 7 days)
sudo find /tmp -type f -mtime +7 -delete
```

**Docker logs:**
```bash
# Check size
du -sh /var/lib/docker/containers/

# Clean Docker logs
sudo truncate -s 0 /var/lib/docker/containers/*/*-json.log
```

**Supervisely data directories:**
```bash
# Check Supervisely directories
du -sh /sly-app-data/
du -sh /supervisely/

# ⚠️ IMPORTANT: Review contents before deleting anything!
# These may contain important project data, models, or datasets
```

**Old cache or build artifacts:**
```bash
# Python cache
find /path/to/projects -type d -name "__pycache__" -exec rm -rf {} +

# Node modules (if applicable)
find /path/to/projects -type d -name "node_modules" -mtime +60
```

### Step 3: Run Automated Docker Cleanup

After manual cleanup, run the automated Docker cleanup:

```bash
bash cleanup-disk.sh
```

This will:
- Remove stopped sly-task containers
- Prune unused Docker images
- Show you how much space was reclaimed

---

## Safety Notes

### ⚠️ Important Warnings

1. **Always check for sensitive data** before deleting any directories
2. **Run check-disk-usage.sh first** to understand what will be deleted
3. **Backup important data** before running cleanup operations
4. **Verify container status** - ensure stopped containers are truly no longer needed
5. **Test in non-production environment first** if possible

### What Gets Deleted

**cleanup-disk.sh removes:**
- ✓ Stopped containers with "sly-task" in the name (safe - these are task containers)
- ✓ Dangling Docker images (safe - these are not linked to any containers)

**cleanup-disk.sh does NOT remove:**
- ✗ Running containers
- ✗ Images currently in use by containers
- ✗ Docker volumes
- ✗ Any files outside of Docker

### Recommended Schedule

- **Weekly:** Run `check-disk-usage.sh` to monitor disk usage trends
- **Monthly:** Run `cleanup-disk.sh` to remove accumulated stopped containers and images
- **As needed:** Perform manual directory cleanup when disk usage is high

---

## Troubleshooting

### Permission Denied Errors

If you encounter permission errors:

```bash
# Run with sudo
sudo bash cleanup-disk.sh

# Or add your user to the docker group
sudo usermod -aG docker $USER
# Then log out and log back in
```

### Script Not Found

Ensure the script has executable permissions:

```bash
chmod +x check-disk-usage.sh cleanup-disk.sh
```

### No Space Left on Device

If disk is completely full:

1. Manually remove some log files first:
   ```bash
   sudo rm /var/log/*.log.1
   ```

2. Then run the cleanup script:
   ```bash
   bash cleanup-disk.sh
   ```

---

## Additional Docker Cleanup Commands

### Remove All Stopped Containers (Not Just sly-task)

```bash
docker container prune -f
```

### Remove All Unused Images (Not Just Dangling)

```bash
docker image prune -a -f
```

### Complete Docker System Cleanup

⚠️ **WARNING:** This removes ALL unused Docker resources!

```bash
docker system prune -a -f --volumes
```

---

## Support

For issues or questions, contact Supervisely support or your system administrator.
