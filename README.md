# Synchro Add-on

A Jelastic JPS add-on that synchronizes files between nodes using rsync over SSH.

**Current Version:** v1.9.1

**Repository:** https://github.com/shaundma/synchro-addon

**Installation URL:**
```
https://raw.githubusercontent.com/shaundma/synchro-addon/master/manifest.jps
```

## Features

- ✅ **Bidirectional sync** - Sync FROM local TO remote or FROM remote TO local
- ✅ **Flexible sync modes** - One-time sync or automatic recurring sync
- ✅ **Separate folder paths** - Sync between different folders on local and remote
- ✅ **Automatic ownership** - Optional chown of local folder after sync TO local completes
- ✅ **Private & Public IPs** - Supports both private network IPs and external servers
- ✅ **Auto environment discovery** - Automatically finds the environment from IP address
- ✅ **Configure button** - Update settings without reinstalling
- ✅ **Sync Now button** - Manually trigger immediate sync
- ✅ **SSH key automation** - Automatic SSH key generation and distribution (private IPs)
- ✅ **Any node type** - Works with storage, web servers, databases, VPS, etc.

## How It Works

### Installation

1. In Jelastic, click **Import** from the top menu
2. Paste the installation URL
3. Fill in the form:
   - **Folder on local** - Path on the node where add-on is installed
   - **Local owner** - Optional: Local user to chown folder after sync TO local (e.g. jelastic)
   - **Folder on remote** - Path on the remote node
   - **Sync Direction** - FROM local TO remote, or FROM remote TO local
   - **Remote User** - Username on remote node (default: root)
   - **Remote Node IP Address** - IP address of remote node
   - **Sync Mode** - One-time sync only (default) or automatic recurring
   - **Every (minutes)** - Minutes between syncs (for automatic mode)
4. Select **Environment** and **Nodes** (the local node where add-on will be installed)
5. Click **Install**

### Private Network IPs

For private network IPs (RFC 1918: 10.x.x.x, 172.16-31.x.x, 192.168.x.x):
- Automatic environment discovery via Jelastic API
- SSH key is automatically distributed to remote node
- No manual setup required
- Sync starts immediately

### Public/External IPs

For public IP addresses or external servers:
- Installation provides the public key
- Manually add the key to `~/.ssh/authorized_keys` for the specified remote user
- Ensure port 22 is accessible
- Use "Sync Now" button to test connection

### Post-Installation

After installation, you'll see two buttons in Application → Add-Ons:

- **Configure** - Change any settings (folders, direction, interval, IP, sync mode)
- **Sync Now** - Manually trigger an immediate sync

## Sync Modes

### One-time Sync Only (Default)
- Initial sync runs during installation
- No automatic syncing
- Use "Sync Now" button to sync manually whenever needed
- Perfect for on-demand syncing
- **This is the default mode** - safer and gives you full control

### Automatic Recurring Sync
- Runs automatically via cron job
- Set interval from 1 to 2880 minutes (48 hours)
- Default interval: every 15 minutes
- Can still use "Sync Now" for immediate sync between scheduled runs

## File Locations

**On local node (where add-on is installed):**
- SSH private key: `/root/.ssh/id_synchro`
- SSH public key: `/root/.ssh/id_synchro.pub`
- Sync script: `/usr/local/bin/synchro-sync.sh`
- Sync log: `/var/log/synchro-addon.log`
- Cron job: `crontab -l` (if automatic mode)

**On remote node:**
- Authorized keys: `/root/.ssh/authorized_keys` (contains local's public key)
- Synced folder: Your configured path

## Testing & Troubleshooting

### Verify SSH key exists
```bash
ls -la /root/.ssh/id_synchro*
```

### Check cron job (automatic mode only)
```bash
crontab -l
```
Should show: `*/15 * * * * /usr/local/bin/synchro-sync.sh` (or your interval)

### Test SSH connectivity
```bash
ssh -i /root/.ssh/id_synchro root@REMOTE_IP echo "test"
```

### Check sync log
```bash
tail -f /var/log/synchro-addon.log
```

### Manual sync test
```bash
/usr/local/bin/synchro-sync.sh
```

### Test file sync
```bash
# Create test file on source
echo "test" > /path/to/local/folder/test.txt

# Wait for sync or click "Sync Now"

# Check on remote
ssh -i /root/.ssh/id_synchro root@REMOTE_IP cat /path/to/remote/folder/test.txt
```

## Version History

### v1.9.1 (2025-11-13)
- Fixed Configure button cron job installation
- Changed setupCronJob from conditional to script-based approach
- Now correctly installs/removes cron job when switching between modes

### v1.9.0 (2025-11-13)
- Added Local owner field (optional)
- Automatic chown -R of local folder after sync TO local completes
- Only runs chown if Local owner is specified and sync direction is TO local
- Updated success messages to show local owner configuration

### v1.8.2 (2025-11-13)
- Improved public IP SSH key installation instructions
- Changed to generic "~/.ssh/authorized_keys in the home of the remote user" wording

### v1.8.1 (2025-11-13)
- Reordered form fields: Remote User now appears above Remote Node IP Address
- Updated README to reflect new field order

### v1.8.0 (2025-11-13)
- Added Remote User field with default "root"
- Support for non-root SSH connections
- Updated sync script to use configurable remote user
- Updated success messages to show remote user
- Updated SSH key removal to work with any user

### v1.7.2 (2025-11-13)
- Updated README with current version and complete version history
- Updated form field descriptions to reflect new order
- Clarified default sync mode documentation
- Updated cache-busting URL example

### v1.7.1 (2025-11-13)
- Fixed Sync Now button to show correct success message
- No longer shows full installation message on manual sync
- Clean, appropriate message for sync operations

### v1.7.0 (2025-11-13)
- Reordered form fields for better flow
- Remote Node IP Address moved above Sync Mode section
- Better logical grouping of connection and sync settings

### v1.6.9 (2025-11-13)
- Changed interval label to "Every (minutes)"
- More concise and clearer labeling

### v1.6.8 (2025-11-13)
- Removed explanatory text in parentheses
- Cleaner form appearance

### v1.6.7 (2025-11-13)
- Attempted to clarify field labels with inline help text

### v1.6.6 (2025-11-13)
- Attempted conditional display of interval field

### v1.6.5 (2025-11-13)
- Changed default sync mode to "One-time sync only"
- Safer default prevents unintended automatic syncing

### v1.6.4 (2025-11-13)
- Fixed sync mode option order using array format
- "One-time sync only" now displays first

### v1.6.3 (2025-11-13)
- Detect all RFC 1918 private IP ranges (10.x, 172.16-31.x, 192.168.x)
- Generic private/public IP detection instead of hardcoded ranges
- Updated documentation to not mention specific IP ranges

### v1.6.2 (2025-11-13)
- Updated README with comprehensive documentation
- Added features list, use cases, and improved troubleshooting guide

### v1.6.1 (2025-11-13)
- Improved sync mode UI with hints
- Shortened field labels for better layout

### v1.6.0 (2025-11-13)
- Added sync mode option: one-time or automatic recurring
- Conditional cron installation based on mode
- Updated success messages with sync mode info

### v1.5.2 (2025-11-13)
- Fixed success message display for email notifications

### v1.5.1 (2025-11-13)
- Simplified external IP instructions

### v1.5.0 (2025-11-13)
- Added external IP support with manual SSH key setup
- Auto-detect internal vs external IPs
- Provide manual installation instructions for external servers

### v1.4.0 (2025-11-13)
- Added Configure button to change settings after installation
- Added Sync Now button for manual triggering

### v1.3.x (2025-11-13)
- Removed Remote Environment selector
- Auto-discover environment from IP address
- Added separate folder paths for local and remote
- Changed "target" terminology to "local" for clarity
- Default sync interval changed to 15 minutes
- Show actual node hostname in success message

### v1.2.6 (2025-11-12)
- Fixed environment name extraction from domain
- All core features working

## Architecture

### manifest.jps
Main JPS file containing:
- Form field definitions
- Installation workflow
- Action definitions for setup, configure, sync
- Button definitions

### scripts/synchro-sync.sh
Template sync script with placeholders:
- `__SYNC_FOLDER__` - Local folder path
- `__REMOTE_SYNC_FOLDER__` - Remote folder path
- `__SYNC_DIRECTION__` - "from" or "to"
- `__REMOTE_IP__` - Remote node IP

Replaced during installation via `sed`.

## Technical Details

### SSH Key Management
- 4096-bit RSA key generated
- Stored as `/root/.ssh/id_synchro`
- For private IPs: Automatically distributed via Jelastic API `ExecCmdById`
- For public IPs: User manually installs

### Sync Script
- Uses rsync with `--delete` flag (mirror mode)
- Logs all operations to `/var/log/synchro-addon.log`
- Bidirectional support via direction parameter

### Cron Job (Automatic Mode)
- Single-line installation command
- Removes old entries before adding new
- Atomic installation via pipe to crontab

### IP Type Detection & Environment Discovery
- Detects RFC 1918 private IP ranges (10.x.x.x, 172.16-31.x.x, 192.168.x.x)
- For private IPs: Searches all accessible environments via `GetEnvs()`
- Finds environment containing node with matching IP
- Works with both `intIP` and `address` fields
- Public IPs skip automatic discovery and key distribution

## Development

### Local Testing
```bash
cd /srv/www/claude/synchro-add-on-v2
# Make changes to manifest.jps or scripts/synchro-sync.sh
git add .
git commit -m "Description"
git push origin master
```

### Cache-Busting
Use timestamp in URL for testing:
```
https://raw.githubusercontent.com/shaundma/synchro-addon/master/manifest.jps?t=20251113191
```

## Use Cases

- **Development environments** - Sync code from dev to staging
- **Backup synchronization** - Copy files to backup node
- **Content deployment** - Push content updates to production
- **Multi-site sync** - Keep multiple sites in sync
- **Database dumps** - Sync backup files between nodes
- **Log aggregation** - Collect logs from multiple nodes

## License

See LICENSE.md

## Support

For issues, feature requests, or questions:
- **GitHub Issues:** https://github.com/shaundma/synchro-addon/issues
- **Jelastic Docs:** https://docs.jelastic.com/jps/
