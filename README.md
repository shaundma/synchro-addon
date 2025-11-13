# Synchro Add-on

A Jelastic JPS add-on that synchronizes files between nodes using rsync over SSH.

**Current Version:** v1.6.2

**Repository:** https://github.com/shaundma/synchro-addon

**Installation URL:**
```
https://raw.githubusercontent.com/shaundma/synchro-addon/master/manifest.jps
```

## Features

- ✅ **Bidirectional sync** - Sync FROM local TO remote or FROM remote TO local
- ✅ **Flexible sync modes** - One-time sync or automatic recurring sync
- ✅ **Separate folder paths** - Sync between different folders on local and remote
- ✅ **Internal & External IPs** - Supports both Jelastic internal IPs and external servers
- ✅ **Auto environment discovery** - Automatically finds the environment from IP address
- ✅ **Configure button** - Update settings without reinstalling
- ✅ **Sync Now button** - Manually trigger immediate sync
- ✅ **SSH key automation** - Automatic SSH key generation and distribution (internal IPs)
- ✅ **Any node type** - Works with storage, web servers, databases, VPS, etc.

## How It Works

### Installation

1. In Jelastic, click **Import** from the top menu
2. Paste the installation URL
3. Fill in the form:
   - **Folder on local** - Path on the node where add-on is installed
   - **Folder on remote** - Path on the remote node
   - **Sync Direction** - FROM local TO remote, or FROM remote TO local
   - **Sync Mode** - One-time or automatic recurring
   - **Interval** - Minutes between syncs (only for automatic mode)
   - **Remote Node IP** - IP address of remote node
4. Select **Environment** and **Nodes** (the local node where add-on will be installed)
5. Click **Install**

### Internal IPs (10.20.x.x)

For Jelastic internal IPs starting with `10.20`:
- SSH key is automatically distributed to remote node
- No manual setup required
- Sync starts immediately

### External IPs

For external servers:
- Installation provides the public key
- Manually add the key to `/root/.ssh/authorized_keys` on remote server
- Ensure port 22 is accessible
- Use "Sync Now" button to test connection

### Post-Installation

After installation, you'll see two buttons in Application → Add-Ons:

- **Configure** - Change any settings (folders, direction, interval, IP, sync mode)
- **Sync Now** - Manually trigger an immediate sync

## Sync Modes

### One-time Sync Only
- Initial sync runs during installation
- No automatic syncing
- Use "Sync Now" button to sync manually
- Perfect for on-demand syncing

### Automatic Recurring Sync
- Runs automatically via cron job
- Set interval from 1 to 2880 minutes (48 hours)
- Default: every 15 minutes
- Can still use "Sync Now" for immediate sync

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
- For internal IPs: Distributed via Jelastic API `ExecCmdById`
- For external IPs: User manually installs

### Sync Script
- Uses rsync with `--delete` flag (mirror mode)
- Logs all operations to `/var/log/synchro-addon.log`
- Bidirectional support via direction parameter

### Cron Job (Automatic Mode)
- Single-line installation command
- Removes old entries before adding new
- Atomic installation via pipe to crontab

### Environment Discovery
- Searches all accessible environments via `GetEnvs()`
- Finds environment containing node with matching IP
- Works with both `intIP` and `address` fields

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
https://raw.githubusercontent.com/shaundma/synchro-addon/master/manifest.jps?t=20251113019
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
