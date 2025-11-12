# Synchro Add-on for Virtuozzo/Jelastic

A JPS (Jelastic Packaging Standard) add-on that synchronizes files and folders between nodes using rsync over SSH.

## Features

- **Bidirectional Sync**: Choose to sync FROM or TO a remote node
- **Flexible Selection**: Select target by IP address or node name
- **Automated Scheduling**: Sync every 1-2880 minutes
- **SSH Key Management**: Automatic SSH key generation and distribution
- **Clean Uninstall**: Removes SSH keys from remote nodes on uninstall
- **Persistent Keys**: SSH keys are preserved for reuse when reinstalling

## Installation

### From Jelastic Marketplace

1. Navigate to your environment in Jelastic dashboard
2. Click **Add-ons** on any node
3. Find **Synchro Add-on** and click **Install**
4. Fill in the configuration form:
   - **Folder to Sync**: Path to the folder you want to synchronize
   - **Sync Direction**:
     - `Sync FROM remote TO this node`: Pull files from remote
     - `Sync FROM this node TO remote`: Push files to remote
   - **Sync Method**: Choose IP or node name
   - **Target Environment**: Select the environment containing the target node
   - **Target Node**: Select the specific node to sync with
   - **Sync Interval**: How often to sync (1-2880 minutes)
   - **Rsync Options**: Advanced rsync flags (default: `-avz --delete`)

### Manual Installation

Upload the `manifest.jps` file to your Jelastic dashboard:

```bash
https://your-repo-url/manifest.jps
```

Or use the Jelastic CLI:

```bash
~/jelastic/environment/control/installpackagebyurl \
  --envName {env-name} \
  --url https://your-repo-url/manifest.jps \
  --nodeGroup {node-group}
```

## Configuration Options

### Folder to Sync
The absolute path to the folder you want to synchronize.

**Examples:**
- `/var/www/webroot/ROOT` (default web root)
- `/data/uploads`
- `/home/user/files`

### Sync Direction

**FROM remote TO this node (Pull)**
- Files on the remote node will be copied to this node
- Local changes may be overwritten
- Use when this node should mirror the remote node

**FROM this node TO remote (Push)**
- Files on this node will be copied to the remote node
- Remote changes may be overwritten
- Use when the remote node should mirror this node

### Sync Method

**By IP Address**
- Uses the internal IP address of the target node
- More reliable for node-to-node communication

**By Node Name**
- Uses the hostname/node name
- May require DNS resolution

### Rsync Options

Default: `-avz --delete`

- `-a`: Archive mode (preserves permissions, timestamps, etc.)
- `-v`: Verbose output
- `-z`: Compress data during transfer
- `--delete`: Delete files on destination that don't exist on source

**Common alternatives:**
- `-avz`: Same as default but keeps deleted files
- `-avz --exclude='*.log'`: Exclude log files
- `-avz --exclude='node_modules/'`: Exclude node_modules directory

## How It Works

### On Installation

1. **Install rsync** if not already present
2. **Generate SSH key** at `/root/.ssh/id_synchro-add-on` (if it doesn't exist)
3. **Copy public key** to target node's `authorized_keys`
4. **Create sync script** at `/usr/local/bin/synchro-addon-sync.sh`
5. **Setup cron job** to run sync at specified interval
6. **Test sync** immediately after installation

### During Operation

- Cron runs the sync script every X minutes
- Script uses rsync over SSH with the dedicated key
- All sync operations are logged to `/var/log/synchro-addon.log`

### On Uninstall

1. **Remove public key** from target node's `authorized_keys`
2. **Remove cron job**
3. **Delete sync script**
4. **Keep SSH key** at `/root/.ssh/id_synchro-add-on` for reuse

## SSH Key Management

The add-on uses a dedicated SSH key named `id_synchro-add-on`:

- **Location**: `/root/.ssh/id_synchro-add-on`
- **Type**: RSA 4096-bit
- **Purpose**: Passwordless SSH for rsync operations

### Key Reuse

If you uninstall and reinstall the add-on:
- The existing SSH key will be reused
- No need to regenerate keys
- Useful when changing sync targets or settings

### Manual Key Removal

If you want to completely remove the key:

```bash
rm -f /root/.ssh/id_synchro-add-on*
```

## Logs

All sync operations are logged to:

```
/var/log/synchro-addon.log
```

View recent logs:

```bash
tail -f /var/log/synchro-addon.log
```

Log format:
```
[2025-11-12 14:30:00] Starting sync: Direction=from, Target=192.168.1.100
[2025-11-12 14:30:05] Sync completed successfully
```

## Manual Sync

To manually trigger a sync without waiting for the cron schedule:

```bash
/usr/local/bin/synchro-addon-sync.sh
```

## Troubleshooting

### Sync Not Working

1. **Check SSH connectivity:**
   ```bash
   ssh -i /root/.ssh/id_synchro-add-on root@<target-ip>
   ```

2. **Verify folder exists:**
   ```bash
   ls -la /path/to/sync/folder
   ```

3. **Check logs:**
   ```bash
   tail -50 /var/log/synchro-addon.log
   ```

4. **Test rsync manually:**
   ```bash
   rsync -avz -e "ssh -i /root/.ssh/id_synchro-add-on" \
     root@<target-ip>:/path/to/folder/ \
     /local/path/
   ```

### Permission Denied

Ensure the target node has the public key in authorized_keys:

```bash
# On target node
cat /root/.ssh/authorized_keys | grep synchro-add-on
```

### Cron Not Running

Check if cron is active:

```bash
crontab -l | grep synchro-addon
```

Verify cron service is running:

```bash
systemctl status crond  # CentOS/RHEL
systemctl status cron   # Debian/Ubuntu
```

## Security Considerations

- SSH keys are stored in `/root/.ssh/` (root access only)
- Keys are used only for rsync operations
- StrictHostKeyChecking is disabled for automated operations
- Consider firewall rules between nodes
- Review rsync options to prevent unintended deletions

## Limitations

- Requires root SSH access between nodes
- Both nodes must have rsync installed
- Network connectivity required between nodes
- Sync interval minimum is 1 minute
- One-way sync only (not true bidirectional)

## Examples

### Example 1: Sync Web Root from Master to Slave

**Use Case**: Keep a slave web server synchronized with master

- Folder: `/var/www/webroot/ROOT`
- Direction: FROM remote TO this node
- Interval: 5 minutes
- Target: Master web server

### Example 2: Backup to Storage Node

**Use Case**: Regular backups to a storage node

- Folder: `/var/www/webroot/ROOT`
- Direction: FROM this node TO remote
- Interval: 60 minutes
- Target: Storage node
- Options: `-avz` (keep old files)

### Example 3: Shared Uploads Folder

**Use Case**: Sync uploaded files from load balancer to application servers

- Folder: `/var/www/webroot/ROOT/uploads`
- Direction: FROM remote TO this node
- Interval: 2 minutes
- Target: Load balancer node

## Changelog

### Version 1.0.0
- Initial release
- Bidirectional sync support
- Automated SSH key management
- Configurable sync intervals
- Clean uninstall with key cleanup

## Support

For issues, questions, or contributions:
- GitHub: https://github.com/shaundma/synchro-addon
- Documentation: https://github.com/shaundma/synchro-addon/wiki

## License

MIT License - See LICENSE file for details
