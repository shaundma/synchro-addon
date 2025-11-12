# Quick Start Guide

Get Synchro Add-on up and running in 5 minutes!

## Installation (3 steps)

### Step 1: Import the Add-on

In your Jelastic dashboard:
1. Navigate to your environment
2. Click on any node (e.g., Apache, Nginx, Tomcat)
3. Click **Add-ons** button
4. Click **Import**
5. Enter URL:
   ```
   https://raw.githubusercontent.com/shaundma/synchro-addon/master/manifest.jps
   ```
6. Click **Install**

### Step 2: Configure Settings

Fill in the installation form:

| Setting | Example | Description |
|---------|---------|-------------|
| **Folder to Sync** | `/var/www/webroot/ROOT` | Path to sync |
| **Sync Direction** | FROM remote TO this node | Pull or Push |
| **Sync Method** | By IP Address | How to identify target |
| **Target Environment** | production-env | Select from list |
| **Target Node** | 192.168.1.100 | Select from list |
| **Sync Interval** | `5` | Minutes between syncs |
| **Rsync Options** | `-avz --delete` | Optional flags |

### Step 3: Install and Verify

1. Click **Install** button
2. Wait for installation to complete (~30 seconds)
3. Check the success message
4. View logs: `/var/log/synchro-addon.log`

## Common Use Cases

### 🔄 Master-Slave Web Server Sync

**Scenario**: Keep slave web servers in sync with master

**Configuration**:
- Install on: **Slave node**
- Folder: `/var/www/webroot/ROOT`
- Direction: **FROM remote TO this node** (Pull from master)
- Target: **Master node**
- Interval: `5` minutes

**Result**: Slave pulls updates from master every 5 minutes

---

### 💾 Backup to Storage

**Scenario**: Regular backups to storage node

**Configuration**:
- Install on: **Web server**
- Folder: `/var/www/webroot/ROOT`
- Direction: **FROM this node TO remote** (Push to storage)
- Target: **Storage node**
- Interval: `60` minutes
- Options: `-avz` (keep deleted files)

**Result**: Web server backs up to storage every hour

---

### 📁 Shared Uploads Directory

**Scenario**: Sync uploaded files across multiple app servers

**Configuration**:
- Install on: **Each app server**
- Folder: `/var/www/webroot/ROOT/uploads`
- Direction: **FROM remote TO this node** (Pull from main)
- Target: **Main app server**
- Interval: `2` minutes

**Result**: All app servers stay in sync with main server

---

## Verification

### Check if Sync is Running

```bash
# View recent sync activity
tail -f /var/log/synchro-addon.log

# Check cron job
crontab -l | grep synchro

# Manual sync test
/usr/local/bin/synchro-addon-sync.sh
```

### Expected Log Output

```
[2025-11-12 14:30:00] Starting sync: Direction=from, Target=192.168.1.100
[2025-11-12 14:30:05] Sync completed successfully
```

## Troubleshooting

### ❌ Problem: "Permission denied"

**Solution**: Check SSH key on target node
```bash
# On target node
cat /root/.ssh/authorized_keys | grep synchro-add-on
```

### ❌ Problem: "Connection refused"

**Solution**: Verify network connectivity
```bash
# Test SSH connection
ssh -i /root/.ssh/id_synchro-add-on root@<target-ip>
```

### ❌ Problem: "Folder not found"

**Solution**: Create the folder first
```bash
mkdir -p /path/to/sync/folder
```

## Next Steps

- 📖 Read full [README.md](README.md) for details
- 🚀 Check [DEPLOYMENT.md](DEPLOYMENT.md) for publishing
- 🔧 View [manifest.jps](manifest.jps) for customization
- 📝 See [CHANGELOG.md](CHANGELOG.md) for version history

## Tips

💡 **Tip 1**: Start with a longer interval (15-30 minutes) and adjust based on needs

💡 **Tip 2**: Use `--dry-run` in rsync options to test before actual sync

💡 **Tip 3**: Monitor logs for the first hour after installation

💡 **Tip 4**: Keep the SSH key (`id_synchro-add-on`) - it's reused on reinstall

## Uninstallation

1. Go to **Add-ons** in Jelastic dashboard
2. Find **Synchro Add-on**
3. Click **Uninstall**
4. Confirm removal

The add-on will:
- ✅ Remove cron job
- ✅ Delete sync script
- ✅ Remove SSH key from target node
- ✅ Keep SSH key on this node for reuse

## Need Help?

- 💬 [Open an issue](https://github.com/shaundma/synchro-addon/issues)
- 📧 Contact support
- 📚 Check [documentation](https://github.com/shaundma/synchro-addon/wiki)
